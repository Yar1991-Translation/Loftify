import 'package:dio/dio.dart';

import 'demo_data.dart';

/// 演示模式假服务器：按 URL 把请求路由到测试数据，形状与线上接口的
/// wire 格式一致（业务层 fromJson 可直接消费）。
///
/// 两种信封：
/// - 常规接口：`{code, msg, data}`（code 0 为成功）
/// - 旧版接口（detail.api / usercounts.api / meInfo.api）：
///   `{meta: {status}, response}`
class DemoServer {
  /// 每个列表接口演示 32 条，翻到头返回空列表触发「没有更多」。
  static const int _poolSize = 32;
  static const int _pageSize = 8;

  static Map<String, dynamic> handle(
    String method,
    String url, {
    Map<String, dynamic>? params,
    dynamic data,
  }) {
    return _route(url, params: params, data: data);
  }

  /// 带 `getFullResponse` 的调用方（短链重定向）需要 Response 外壳。
  static Response wrapResponse(String url, Map<String, dynamic> body) {
    return Response(
      requestOptions: RequestOptions(path: url),
      statusCode: 200,
      redirects: const [],
      data: body,
    );
  }

  static Map<String, dynamic> _route(
    String url, {
    Map<String, dynamic>? params,
    dynamic data,
  }) {
    final query = <String, dynamic>{};
    if (params != null) query.addAll(params);
    if (data is Map) {
      data.forEach((key, value) => query['$key'] = value);
    }
    switch (url) {
      case '/recommend/exploreRecom.json':
      case '/recommend/postRecom.json':
      case '/newapi/tagPosts.json':
      case '/newsearch/tag/post.json':
        return _postListPage(query);
      case '/recommend/postVideoFlow.json':
        // 视频流暂不演示，回空列表走「没有更多」。
        return _ok({'list': <dynamic>[], 'offset': 0});
      case '/recommend/relatedTagRecom.json':
      case '/recommend/tagRecom.json':
        return _ok({
          'list': List.generate(
            4,
            (i) => {'tag': DemoData.demoTagInfo(i)['tagName']},
          ),
        });
      case '/newsearch/v2/all.json':
      case '/newsearch/all/post.json':
        final offset = _offsetOf(query);
        return _ok({
          'posts': _pool(offset, DemoData.demoPostListItem),
          'tags': List.generate(4, DemoData.demoTagInfo),
          'tagRank': DemoData.demoTagInfo(0),
          'hasResult': true,
          'jumpTag': false,
          'offset': _next(offset),
        });
      case '/newsearch/post.json':
        final offset = _offsetOf(query);
        return _ok({
          'posts': _pool(offset, DemoData.demoSearchPost),
          'offset': _next(offset),
        });
      case '/newsearch/tag.json':
        final offset = _offsetOf(query);
        return _ok({
          'tags': _pool(offset, DemoData.demoTagInfo),
          'tagRank': DemoData.demoTagInfo(0),
          'offset': _next(offset),
        });
      case '/newsearch/collection.json':
        final offset = _offsetOf(query);
        return _ok({
          'collections': _pool(offset, DemoData.demoCollection),
          'offset': _next(offset),
        });
      case '/newsearch/blog.json':
      case '/newsearch/grain.json':
        return _ok({'posts': <dynamic>[], 'offset': 0});
      case '/newsearch/guess/keywords.json':
        return _ok({
          'guessKeywords': List.generate(6, DemoData.demoGuessKeyword),
        });
      case '/newapi/hotsearch/ranklist.json':
        return _ok({
          'rankList': [
            {
              'hotLists': List.generate(5, DemoData.demoRankItem),
              'listName': '演示热榜',
              'ruleUrl': '',
              'sortNo': 0,
              // RankListType.values[type]，2 = unset 最安全。
              'type': 2,
            },
          ],
          'configList': <dynamic>[],
        });
      case '/newsearch/sug.json':
        return _ok({
          'items': List.generate(4, DemoData.demoSuggestItem),
        });
      case '/comment/l1/hotnew.json':
        final postId = _intOf(query, 'postId');
        return _ok({
          'hotTotal': 6,
          'hotList': List.generate(
            3,
            (i) => DemoData.demoComment(i, postId: postId),
          ),
          'list': List.generate(
            3,
            (i) => DemoData.demoComment(i + 3, postId: postId),
          ),
        });
      case '/comment/l1/page.json':
      case '/comment/l2/page.json':
        final offset = _offsetOf(query);
        final postId = _intOf(query, 'postId');
        return _ok({
          'list': _pool(offset, (i) => DemoData.demoComment(i, postId: postId)),
          'offset': _next(offset),
        });
      case '/oldapi/post/detail.api':
        final postId = _intOf(query, 'postId');
        final post = DemoData.demoPostDetail(postId % _poolSize);
        post['id'] = postId;
        return _okMeta({
          'posts': [
            {
              'post': post,
              'liked': false,
              'shared': false,
              'subscribed': false,
              'followed': 0,
              'opTime': 0,
            },
          ],
        });
      case '/timeline/app/getTrackItemListWithShare.json':
        final offset = _intOf(query, 'showOffset');
        return _ok({
          'items': _pool(offset, DemoData.demoGrainPostItem),
          'timelineBlogList': <dynamic>[],
          'showOffset': _next(offset),
          'publishOffset': 0,
          'shareOffset': 0,
        });
      case '/v1.1/usercounts.api':
        return _okMeta(DemoData.demoAccountResponse());
      case '/v1.1/meInfo.api':
        return _okMeta(DemoData.demoMeInfo());
      default:
        // 未知端点一律成功空数据，并同时带齐两种信封的键，
        // 避免演示被错误弹窗打断。
        return {
          'code': 0,
          'msg': '',
          'data': {'list': <dynamic>[], 'items': <dynamic>[], 'offset': 0},
          'meta': {'status': 200, 'desc': '', 'msg': ''},
          'response': <String, dynamic>{},
        };
    }
  }

  /// 常规信封；同时补上 meta/response 兜底键，兼容两种读法。
  static Map<String, dynamic> _ok(Map<String, dynamic> data) => {
        'code': 0,
        'msg': '',
        'data': data,
        'meta': {'status': 200, 'desc': '', 'msg': ''},
        'response': data,
      };

  static Map<String, dynamic> _okMeta(Map<String, dynamic> response) => {
        'meta': {'status': 200, 'desc': '', 'msg': ''},
        'response': response,
        'code': 0,
        'msg': '',
        'data': response,
      };

  /// 帖子列表页：不同界面读 `list` / `postList` / `posts` 三种键，
  /// 统一全部带上（同一份列表）。
  static Map<String, dynamic> _postListPage(Map<String, dynamic> query) {
    final offset = _offsetOf(query);
    final items = _pool(offset, DemoData.demoPostListItem);
    return _ok({
      'list': items,
      'postList': items,
      'posts': items,
      'offset': _next(offset),
    });
  }

  /// 生成一页数据；越过 [_poolSize] 返回空列表，让分页控件收尾。
  static List<Map<String, dynamic>> _pool(
    int offset,
    Map<String, dynamic> Function(int seed) builder,
  ) {
    if (offset >= _poolSize) return <Map<String, dynamic>>[];
    final end = (offset + _pageSize).clamp(0, _poolSize);
    return List.generate(end - offset, (i) => builder(offset + i));
  }

  static int _offsetOf(Map<String, dynamic> query) =>
      int.tryParse('${query['offset'] ?? 0}') ?? 0;

  static int _intOf(Map<String, dynamic> query, String key) =>
      int.tryParse('${query[key] ?? 0}') ?? 0;

  static int _next(int offset) => (offset + _pageSize).clamp(0, _poolSize);
}
