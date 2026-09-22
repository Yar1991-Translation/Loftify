import 'dart:convert';

import 'package:awesome_chewie/awesome_chewie.dart';

import '../Models/recommend_response.dart';
import 'hive_util.dart';
import 'llm_util.dart';

/// The dimensions along which tag posts are classified for a fandom tag.
enum TagLlmDimension {
  cp,
  ending,
  kind,
}

extension TagLlmDimensionX on TagLlmDimension {
  String get storageKey => switch (this) {
        TagLlmDimension.cp => 'cp',
        TagLlmDimension.ending => 'ending',
        TagLlmDimension.kind => 'kind',
      };

  String get jsonField => storageKey;
}

/// One post's LLM-assigned fandom attributes inside a tag.
class TagClassification {
  const TagClassification({
    required this.cp,
    required this.ending,
    required this.kind,
    required this.classifiedAt,
  });

  /// Core ship of the post in the fandom's common abbreviation ("蜂狼"),
  /// "单人" for character-focused pieces without a ship, "全员" for
  /// ensemble works, empty when undeterminable.
  final String cp;

  /// Story ending: BE / HE / OE, empty for non-story content.
  final String ending;

  /// Content form: 同人文 / 绘画 / cos / 语音视频 / 闲聊 / 攻略 …
  final String kind;

  final int classifiedAt;

  bool get hasAnyValue => cp.isNotEmpty || ending.isNotEmpty || kind.isNotEmpty;

  String? valueOf(TagLlmDimension dimension) => switch (dimension) {
        TagLlmDimension.cp => cp.isEmpty ? null : cp,
        TagLlmDimension.ending => ending.isEmpty ? null : ending,
        TagLlmDimension.kind => kind.isEmpty ? null : kind,
      };

  Map<String, dynamic> toJson() => {
        'cp': cp,
        'ending': ending,
        'kind': kind,
        'at': classifiedAt,
      };

  static TagClassification fromJson(dynamic json) {
    if (json is Map) {
      return TagClassification(
        cp: json['cp']?.toString() ?? '',
        ending: json['ending']?.toString() ?? '',
        kind: json['kind']?.toString() ?? json['category']?.toString() ?? '',
        classifiedAt: (json['at'] as num?)?.toInt() ?? 0,
      );
    }
    return const TagClassification(
      cp: '',
      ending: '',
      kind: '',
      classifiedAt: 0,
    );
  }
}

/// LLM classification for the posts of one tag.
///
/// Posts already loaded in a tag detail screen are sent to the configured
/// OpenAI-compatible endpoint in small concurrent batches; every post gets
/// fandom attributes (ship, ending, content form). Results persist per tag
/// so the filter is available on later visits, and newly loaded posts can be
/// classified incrementally.
abstract class TagLlmClassifier {
  static const int _batchSize = 16;

  static String _storageKey(String tag) =>
      "${HiveUtil.llmTagClassificationsKey}_${tag.toLowerCase()}";

  static Map<int, TagClassification> load(String tag) {
    final raw = ChewieHiveUtil.getString(_storageKey(tag));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final result = <int, TagClassification>{};
      decoded.forEach((key, value) {
        final id = int.tryParse(key.toString());
        if (id == null) return;
        result[id] = TagClassification.fromJson(value);
      });
      return result;
    } catch (error, stackTrace) {
      ILogger.error("Failed to load tag LLM classifications", error, stackTrace);
      return {};
    }
  }

  static void _save(String tag, Map<int, TagClassification> data) {
    final encoded = jsonEncode({
      for (final entry in data.entries)
        entry.key.toString(): entry.value.toJson(),
    });
    ChewieHiveUtil.put(_storageKey(tag), encoded);
  }

  static void clear(String tag) {
    ChewieHiveUtil.delete(_storageKey(tag));
  }

  /// The active filter for [tag], persisted so re-entering the tag restores
  /// the last chosen dimension/value instead of silently dropping it.
  static (TagLlmDimension, String)? loadFilter(String tag) {
    final raw =
        ChewieHiveUtil.getString("${HiveUtil.llmTagFilterKey}_${tag.toLowerCase()}");
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final dimension = TagLlmDimension.values.firstWhere(
        (d) => d.storageKey == decoded['dimension'],
        orElse: () => TagLlmDimension.cp,
      );
      final value = decoded['value']?.toString() ?? '';
      if (value.isEmpty) return null;
      return (dimension, value);
    } catch (error, stackTrace) {
      ILogger.error("Failed to load tag LLM filter", error, stackTrace);
      return null;
    }
  }

  static void saveFilter(String tag, TagLlmDimension? dimension, String? value) {
    final key = "${HiveUtil.llmTagFilterKey}_${tag.toLowerCase()}";
    if (dimension == null || value == null || value.isEmpty) {
      ChewieHiveUtil.delete(key);
      return;
    }
    ChewieHiveUtil.put(key, jsonEncode({
      'dimension': dimension.storageKey,
      'value': value,
    }));
  }

  /// Human-readable digest of a post for the classifier: title plus the
  /// first slice of the text digest keeps each batch small enough for one
  /// completion while still describing the content.
  static String postDigest(PostListItem post) {
    final postView = post.postData?.postView;
    final title = postView?.title.trim() ?? '';
    final digest = postView?.digest.trim() ?? '';
    final text =
        '${title.isEmpty ? '' : '$title\n'}${digest.length > 120 ? digest.substring(0, 120) : digest}';
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String systemPromptFor(String tag) =>
      '你是同人内容分类助手。用户会给你 LOFTER 标签「$tag」下的内容列表，'
      '每条以「编号. 标题 摘要」的格式给出。请为每条内容判断以下三个维度：\n'
      '1. cp：这篇内容的核心配对（CP），使用该同人圈最通用的中文简称'
      '（如"蜂狼""狼龙""液回"）。单人向/无 CP 的内容填"单人"，'
      '全员群像/多 CP 大杂烩填"全员"，无法判断时留空字符串。\n'
      '2. ending：结局走向，只能是 BE、HE、OE 三者之一'
      '（BE=悲剧结局，HE=圆满结局，OE=开放结局）；'
      '不是故事类内容（纯绘画、cos、语音、闲聊、攻略等）填"无"。\n'
      '3. kind：内容形式，用 2-6 个汉字，如：同人文、绘画、cos、语音视频、'
      '日常闲聊、攻略、考据分析。同一形式的条目必须使用完全相同的词。\n'
      '要求：同一 CP 的条目必须使用完全相同的简称，先通读全部条目再定。'
      '只输出一个 JSON 对象，格式为 '
      '{"文章编号": {"cp": "...", "ending": "...", "kind": "..."}}，'
      '不要输出任何其他文字。';

  /// Classifies [posts] (skipping ones already classified) and persists the
  /// result. Batches run concurrently through a small worker pool — the
  /// endpoint has no rate limit and sequential batches waste it. Returns the
  /// full classification map for the tag afterwards; failed batches are
  /// skipped (their posts stay unclassified and a retry only sends those).
  static Future<Map<int, TagClassification>> classify(
    String tag,
    List<PostListItem> posts, {
    void Function(int done, int total)? onProgress,
    LlmConfig? config,
    int concurrency = 4,
  }) async {
    final conf = config ?? LlmConfig.load();
    if (!conf.isConfigured) {
      throw LlmException('LLM is not configured');
    }
    final existing = load(tag);
    final pending = posts
        .where((post) =>
            !(existing[post.itemId]?.hasAnyValue ?? false))
        .toList(growable: false);
    final batches = <List<PostListItem>>[
      for (var i = 0; i < pending.length; i += _batchSize)
        pending.sublist(i, (i + _batchSize).clamp(0, pending.length)),
    ];
    final total = pending.length;
    var done = 0;
    onProgress?.call(0, total);
    var nextBatch = 0;
    var failed = 0;
    Object? firstError;
    Future<void> worker() async {
      while (nextBatch < batches.length) {
        final batch = batches[nextBatch++];
        try {
          final userContent = StringBuffer();
          for (var i = 0; i < batch.length; i++) {
            userContent.writeln('${i + 1}. ${postDigest(batch[i])}');
          }
          final completion = await LlmUtil.chat(
            config: conf,
            system: systemPromptFor(tag),
            user: userContent.toString(),
            jsonMode: true,
          );
          final parsed = LlmUtil.extractJsonObject(completion);
          final now = DateTime.now().millisecondsSinceEpoch;
          var assigned = 0;
          for (var i = 0; i < batch.length; i++) {
            final entry = parsed[(i + 1).toString()];
            if (entry is! Map) continue;
            final classification = TagClassification(
              cp: entry['cp']?.toString().trim() ?? '',
              ending: entry['ending']?.toString().trim() ?? '',
              kind: entry['kind']?.toString().trim() ?? '',
              classifiedAt: now,
            );
            if (!classification.hasAnyValue) continue;
            existing[batch[i].itemId] = classification;
            assigned++;
          }
          if (assigned == 0) {
            throw LlmException('LLM returned no usable classification');
          }
          _save(tag, existing);
        } catch (error) {
          failed++;
          firstError ??= error;
        } finally {
          done += batch.length;
          onProgress?.call(done.clamp(0, total), total);
        }
      }
    }

    await Future.wait([
      for (var i = 0; i < concurrency && i < batches.length; i++) worker(),
    ]);
    if (failed == batches.length && batches.isNotEmpty) {
      throw firstError!;
    }
    return existing;
  }

  /// Value counts for one dimension, ordered descending. Only posts present
  /// in [posts] count (the sheet shows what a filter would actually show).
  static List<(String, int)> valuesWithCounts(
    TagLlmDimension dimension,
    Map<int, TagClassification> classifications,
    Iterable<PostListItem> posts,
  ) {
    final counts = <String, int>{};
    for (final post in posts) {
      final value = classifications[post.itemId]?.valueOf(dimension);
      if (value == null || value.isEmpty) continue;
      counts[value] = (counts[value] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [for (final entry in entries) (entry.key, entry.value)];
  }
}
