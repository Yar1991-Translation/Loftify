import 'dart:convert';

import 'package:awesome_chewie/awesome_chewie.dart';

import '../Models/recommend_response.dart';
import 'hive_util.dart';
import 'llm_util.dart';

/// One post's LLM-assigned category inside a tag.
class TagClassification {
  const TagClassification({
    required this.category,
    required this.classifiedAt,
  });

  final String category;
  final int classifiedAt;

  Map<String, dynamic> toJson() => {'category': category, 'at': classifiedAt};

  static TagClassification fromJson(dynamic json) {
    if (json is Map) {
      return TagClassification(
        category: json['category']?.toString() ?? '',
        classifiedAt: (json['at'] as num?)?.toInt() ?? 0,
      );
    }
    // Legacy/foreign values degrade to an unclassified entry.
    return TagClassification(category: '', classifiedAt: 0);
  }
}

/// LLM classification for the posts of one tag.
///
/// Posts already loaded in a tag detail screen are sent to the configured
/// OpenAI-compatible endpoint in small batches; every post gets one short
/// category label. Results persist per tag so the filter is available on
/// later visits, and newly loaded posts can be classified incrementally.
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

  static String systemPromptFor(String tag) => '你是内容分类助手。用户会给你 LOFTER '
      '标签「$tag」下的文章列表，每篇以「编号. 标题 摘要」的格式给出。'
      '请为每篇文章指定一个最能概括其内容类型或主题的中文分类。\n'
      '要求：\n'
      '1. 分类名用 2-6 个汉字，例如：同人图文、原创小说、cos、攻略、绘画、'
      '语音视频、日常闲聊、考据分析。\n'
      '2. 相同类型的文章必须使用完全相同的分类名；先通读全部文章再定类别。\n'
      '3. 只输出一个 JSON 对象，格式为 {"文章编号": "分类名"}，不要输出任何其他文字。';

  /// Classifies [posts] (skipping ones already classified) and persists the
  /// result. Returns the full classification map for the tag afterwards.
  static Future<Map<int, TagClassification>> classify(
    String tag,
    List<PostListItem> posts, {
    void Function(int done, int total)? onProgress,
    LlmConfig? config,
  }) async {
    final conf = config ?? LlmConfig.load();
    if (!conf.isConfigured) {
      throw LlmException('LLM is not configured');
    }
    final existing = load(tag);
    final pending = posts
        .where((post) => !existing.containsKey(post.itemId))
        .toList(growable: false);
    final total = pending.length;
    onProgress?.call(0, total);
    for (var start = 0; start < pending.length; start += _batchSize) {
      final batch = pending.sublist(
        start,
        (start + _batchSize).clamp(0, pending.length),
      );
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
        final category = parsed[(i + 1).toString()]?.toString().trim() ?? '';
        if (category.isEmpty || category.length > 12) continue;
        existing[batch[i].itemId] =
            TagClassification(category: category, classifiedAt: now);
        assigned++;
      }
      if (assigned == 0) {
        throw LlmException('LLM returned no usable classification');
      }
      _save(tag, existing);
      onProgress?.call(
        (start + batch.length).clamp(0, total),
        total,
      );
    }
    return existing;
  }

  /// Category labels currently in use for [tag], ordered by post count.
  static List<(String, int)> categoriesWithCounts(
    String tag,
    Iterable<PostListItem> posts,
  ) {
    final classifications = load(tag);
    final counts = <String, int>{};
    for (final post in posts) {
      final category = classifications[post.itemId]?.category;
      if (category == null || category.isEmpty) continue;
      counts[category] = (counts[category] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [for (final entry in entries) (entry.key, entry.value)];
  }
}
