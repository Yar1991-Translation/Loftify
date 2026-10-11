import 'dart:convert';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:hive/hive.dart';

import '../Models/ao3_feed_entry.dart';
import 'hive_util.dart';

/// Followed tags and the cached listing for each, stored in the existing
/// Hive boxes so no new box or migration is needed.
abstract final class Ao3Tags {
  static List<String> followed() {
    try {
      final raw = ChewieHiveUtil.getString(HiveUtil.ao3FollowedTagsKey) ?? '';
      if (raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> follow(String tag) async {
    final current = followed();
    final normalized = tag.trim();
    if (normalized.isEmpty || current.contains(normalized)) return;
    final next = [...current, normalized];
    await _write(next);
  }

  static Future<void> unfollow(String tag) async {
    final next = followed().where((e) => e != tag.trim()).toList();
    await _write(next);
  }

  static Future<void> _write(List<String> tags) async {
    await ChewieHiveUtil.put(
      HiveUtil.ao3FollowedTagsKey,
      jsonEncode(tags),
    );
  }

  /// Suggestions from works the reader already cached, most useful first.
  ///
  /// Reading these decodes cached work JSON, so only the most recent
  /// [maxWorks] entries are scanned — the list is a shortcut, not a report.
  static List<String> suggestions({int maxWorks = 20}) {
    final counts = <String, int>{};
    try {
      final box = Hive.box<dynamic>(HiveUtil.ao3Box);
      final keys = box.keys
          .whereType<String>()
          .where((key) => key.startsWith('work:'))
          .toList();
      final recent = keys.length > maxWorks
          ? keys.sublist(keys.length - maxWorks)
          : keys;
      for (final key in recent) {
        final raw = box.get(key);
        if (raw is! String || raw.isEmpty) continue;
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final groups = json['tagGroups'] as List<dynamic>? ?? const [];
        for (final group in groups) {
          final values = (group as Map<String, dynamic>)['values'] as List<dynamic>? ?? const [];
          for (final value in values) {
            final tag = value.toString();
            if (tag.isEmpty) continue;
            counts[tag] = (counts[tag] ?? 0) + 1;
          }
        }
      }
    } catch (_) {
      return const [];
    }
    final ranked = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ranked.map((e) => e.key).take(24).toList();
  }

  static String feedKey(String tag) => 'feed:${tag.trim()}';

  static CachedFeed? readFeed(String tag) {
    try {
      final box = Hive.box<dynamic>(HiveUtil.ao3Box);
      final raw = box.get(feedKey(tag));
      if (raw is! String || raw.isEmpty) return null;
      return CachedFeed.decode(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> writeFeed(String tag, List<Ao3FeedEntry> entries) async {
    final cache = CachedFeed(
      fetchedAtMs: DateTime.now().millisecondsSinceEpoch,
      entries: entries,
    );
    final box = Hive.box<dynamic>(HiveUtil.ao3Box);
    await box.put(feedKey(tag), cache.encode());
  }

  static bool isFresh(CachedFeed? cache, {Duration ttl = const Duration(minutes: 15)}) {
    if (cache == null) return false;
    final age = DateTime.now().millisecondsSinceEpoch - cache.fetchedAtMs;
    return age >= 0 && age < ttl.inMilliseconds;
  }
}

class CachedFeed {
  const CachedFeed({required this.fetchedAtMs, required this.entries});

  final int fetchedAtMs;
  final List<Ao3FeedEntry> entries;

  String encode() => jsonEncode(<String, dynamic>{
        'fetchedAtMs': fetchedAtMs,
        'entries': Ao3FeedEntry.listToJson(entries),
      });

  static CachedFeed decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return CachedFeed(
      fetchedAtMs: json['fetchedAtMs'] as int? ?? 0,
      entries: Ao3FeedEntry.listFromJson(
          json['entries'] as List<dynamic>? ?? const []),
    );
  }
}
