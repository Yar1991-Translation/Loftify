import 'dart:convert';

import 'package:hive/hive.dart';

import '../Models/ao3_work.dart';
import 'ao3_config.dart';
import 'hive_util.dart';

/// Shelf row for a saved work: metadata plus reading progress. The parsed work
/// is cached under its own key so the shelf stays cheap to load.
class Ao3LibraryEntry {
  const Ao3LibraryEntry({
    required this.id,
    required this.title,
    this.author = '',
    this.chapterCount = 1,
    this.words,
    this.savedAtMs = 0,
    this.lastReadAtMs = 0,
    this.chapterIndex = 1,
    this.cached = false,
  });

  final int id;
  final String title;
  final String author;
  final int chapterCount;
  final int? words;
  final int savedAtMs;
  final int lastReadAtMs;
  final int chapterIndex;

  /// False when the work was too large to keep offline.
  final bool cached;

  Ao3LibraryEntry copyWith({
    int? chapterIndex,
    int? lastReadAtMs,
    bool? cached,
  }) =>
      Ao3LibraryEntry(
        id: id,
        title: title,
        author: author,
        chapterCount: chapterCount,
        words: words,
        savedAtMs: savedAtMs,
        lastReadAtMs: lastReadAtMs ?? this.lastReadAtMs,
        chapterIndex: chapterIndex ?? this.chapterIndex,
        cached: cached ?? this.cached,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'chapterCount': chapterCount,
        'words': words,
        'savedAtMs': savedAtMs,
        'lastReadAtMs': lastReadAtMs,
        'chapterIndex': chapterIndex,
        'cached': cached,
      };

  factory Ao3LibraryEntry.fromJson(Map<String, dynamic> json) =>
      Ao3LibraryEntry(
        id: json['id'] as int? ?? 0,
        title: json['title']?.toString() ?? '',
        author: json['author']?.toString() ?? '',
        chapterCount: json['chapterCount'] as int? ?? 1,
        words: json['words'] as int?,
        savedAtMs: json['savedAtMs'] as int? ?? 0,
        lastReadAtMs: json['lastReadAtMs'] as int? ?? 0,
        chapterIndex: json['chapterIndex'] as int? ?? 1,
        cached: json['cached'] as bool? ?? false,
      );
}

/// Offline shelf for AO3 works, backed by the `ao3` Hive box.
class Ao3Store {
  Ao3Store({
    Box? box,
    this.maxCachedBytes = defaultMaxCachedBytes,
    int Function()? now,
  })  : _injected = box,
        _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  final Box? _injected;

  /// A 20 MB epic should not be copied into the box; such works stay
  /// online-only and keep just their shelf row and progress.
  final int maxCachedBytes;

  final int Function() _now;

  Box get _box => _injected ?? Hive.box(HiveUtil.ao3Box);

  static const String libraryKey = 'library';
  static const String workPrefix = 'work:';

  static const int defaultMaxCachedBytes = 4 * 1024 * 1024;

  static String workKey(int id) => workPrefix + id.toString();

  /// Newest read first.
  List<Ao3LibraryEntry> entries() {
    final raw = _box.get(libraryKey);
    if (raw is! String || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final entries = decoded
          .whereType<Map>()
          .map((e) => Ao3LibraryEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      entries.sort((a, b) => b.lastReadAtMs.compareTo(a.lastReadAtMs));
      return entries;
    } catch (_) {
      return const [];
    }
  }

  Ao3LibraryEntry? entry(int id) {
    for (final item in entries()) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Cached work, or null when it was never saved / was too large / was pruned.
  Ao3Work? read(int id) {
    final raw = _box.get(workKey(id));
    if (raw is! String || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Ao3Work.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  bool isCached(int id) => read(id) != null;

  /// Upserts [work], caches its body when small enough and prunes the LRU.
  Future<void> save(Ao3Work work) async {
    final now = _now();
    final encoded = jsonEncode(work.copyWith(fetchedAtMs: now).toJson());
    final canCache = encoded.length <= maxCachedBytes;
    if (canCache) {
      await _box.put(workKey(work.id), encoded);
    } else {
      await _box.delete(workKey(work.id));
    }
    final previous = entry(work.id);
    final list = entries().where((e) => e.id != work.id).toList()
      ..add(Ao3LibraryEntry(
        id: work.id,
        title: work.title,
        author: work.author,
        chapterCount: work.chapters.length,
        words: work.words,
        savedAtMs: previous?.savedAtMs ?? now,
        lastReadAtMs: now,
        chapterIndex: previous?.chapterIndex ?? 1,
        cached: canCache,
      ));
    await _writeLibrary(list);
    await prune();
  }

  Future<void> updateProgress(int id, int chapterIndex) async {
    final now = _now();
    final list = entries()
        .map((e) => e.id == id
            ? e.copyWith(chapterIndex: chapterIndex, lastReadAtMs: now)
            : e)
        .toList();
    if (list.isEmpty) return;
    await _writeLibrary(list);
  }

  Future<void> remove(int id) async {
    await _box.delete(workKey(id));
    await _writeLibrary(entries().where((e) => e.id != id).toList());
  }

  Future<void> clear() async {
    for (final key in _box.keys.toList()) {
      if (key is String && key.startsWith(workPrefix)) {
        await _box.delete(key);
      }
    }
    await _box.delete(libraryKey);
  }

  int cachedBytes() {
    var total = 0;
    for (final key in _box.keys) {
      if (key is String && key.startsWith(workPrefix)) {
        final value = _box.get(key);
        if (value is String) total += value.length;
      }
    }
    return total;
  }

  /// Keeps at most `cacheLimit` cached works, dropping the least recently read.
  Future<void> prune() async {
    final limit = Ao3Config.load().cacheLimit;
    if (limit <= 0) return;
    final cached = entries().where((e) => e.cached).toList();
    if (cached.length <= limit) return;
    final stale = cached.sublist(limit);
    for (final item in stale) {
      await _box.delete(workKey(item.id));
    }
    final staleIds = stale.map((e) => e.id).toSet();
    await _writeLibrary(entries()
        .map((e) => staleIds.contains(e.id) ? e.copyWith(cached: false) : e)
        .toList());
  }

  Future<void> _writeLibrary(List<Ao3LibraryEntry> list) async {
    await _box.put(
        libraryKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }
}
