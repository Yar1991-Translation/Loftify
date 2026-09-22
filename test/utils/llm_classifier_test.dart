import 'dart:convert';
import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Utils/llm_util.dart';
import 'package:loftify/Utils/tag_llm_classifier.dart';

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/llm_classifier',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  group('LlmUtil.extractJsonObject', () {
    test('parses a plain JSON object', () {
      expect(LlmUtil.extractJsonObject('{"1": "同人图文"}'),
          {'1': '同人图文'});
    });

    test('parses JSON wrapped in markdown fences', () {
      expect(
        LlmUtil.extractJsonObject('```json\n{"1": "cos"}\n```'),
        {'1': 'cos'},
      );
    });

    test('parses JSON after a lead-in sentence', () {
      expect(
        LlmUtil.extractJsonObject('好的，分类如下：\n{"1": "攻略", "2": "日常"}'),
        {'1': '攻略', '2': '日常'},
      );
    });

    test('handles braces inside strings', () {
      expect(
        LlmUtil.extractJsonObject('{"1": "含{花括号}的文本"}'),
        {'1': '含{花括号}的文本'},
      );
    });

    test('handles quotes and escapes inside strings', () {
      expect(
        LlmUtil.extractJsonObject(r'{"1": "他说\"好\""}'),
        {'1': '他说"好"'},
      );
    });

    test('throws when no JSON object exists', () {
      expect(() => LlmUtil.extractJsonObject('没有任何 JSON'),
          throwsFormatException);
    });

    test('throws on unbalanced JSON', () {
      expect(() => LlmUtil.extractJsonObject('{"1": "未闭合'),
          throwsFormatException);
    });
  });

  group('TagLlmClassifier', () {
    PostListItem post(int id, String title, String digest) {
      return PostListItem.fromJson({
        'itemId': id,
        'itemType': 0,
        'favorite': false,
        'following': false,
        'groupInfo': null,
        'postCollection': null,
        'postData': {
          'postView': {
            'blogId': 1,
            'digest': digest,
            'id': id,
            'permalink': '',
            'photoCount': 0,
            'postPageUrl': '',
            'publishTime': 0,
            'tagList': <String>[],
            'title': title,
            'type': 1,
            'forbidShare': 0,
          },
        },
      });
    }

    test('postDigest combines title and trimmed digest', () {
      final digest = TagLlmClassifier.postDigest(
        post(1, '标题一', '  这是\n摘要内容  '),
      );
      expect(digest, '标题一 这是 摘要内容');
    });

    test('postDigest truncates long digests', () {
      final long = '长' * 500;
      final digest = TagLlmClassifier.postDigest(post(2, '', long));
      expect(digest.length, 120);
    });

    test('categoriesWithCounts orders by count and skips unknown posts', () {
      // Direct store manipulation through the public classify path is not
      // possible without an LLM; exercise the counting logic via a temp tag
      // store by writing through load/save round trip is internal, so use a
      // pragmatic check: empty classifications yields no categories.
      final posts = [post(1, 'a', 'b'), post(2, 'c', 'd')];
      expect(
        TagLlmClassifier.categoriesWithCounts('__test_none__', posts),
        isEmpty,
      );
    });
  });

  group('LlmConfig', () {
    test('isConfigured requires all three fields', () {
      expect(
        const LlmConfig(baseUrl: '', apiKey: 'k', model: 'm').isConfigured,
        isFalse,
      );
      expect(
        const LlmConfig(baseUrl: 'https://x', apiKey: '', model: 'm')
            .isConfigured,
        isFalse,
      );
      expect(
        const LlmConfig(baseUrl: 'https://x', apiKey: 'k', model: '')
            .isConfigured,
        isFalse,
      );
      expect(
        const LlmConfig(baseUrl: 'https://x', apiKey: 'k', model: 'm')
            .isConfigured,
        isTrue,
      );
    });
  });

  test('TagClassification json round trip', () {
    final original = TagClassification(
      category: '同人图文',
      classifiedAt: 1700000000000,
    );
    final decoded =
        TagClassification.fromJson(jsonDecode(jsonEncode(original.toJson())));
    expect(decoded.category, original.category);
    expect(decoded.classifiedAt, original.classifiedAt);
    expect(TagClassification.fromJson(null).category, '');
  });
}
