import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Api/demo/demo_data.dart';
import 'package:loftify/Api/demo/demo_server.dart';
import 'package:loftify/Models/account_response.dart';
import 'package:loftify/Models/collection_response.dart';
import 'package:loftify/Models/grain_response.dart';
import 'package:loftify/Models/post_detail_response.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Models/search_response.dart';

/// 契约测试：演示模式的测试数据必须能被业务层真实的 fromJson 消费。
/// wire keys 改动时这里先红，避免演示跑起来才发现解析炸了。
void main() {
  Map<String, dynamic> call(String url, {Map<String, dynamic>? params}) =>
      DemoServer.handle('GET', url, params: params);

  test('explore feed items parse as PostListItem', () {
    final body = call('/recommend/exploreRecom.json', params: {'offset': '0'});
    expect(body['code'], 0);
    final list = body['data']['list'] as List;
    expect(list, hasLength(8));
    for (final raw in list) {
      final item = PostListItem.fromJson(Map<String, dynamic>.from(raw));
      expect(item.postData?.postView.id, isNonZero);
    }
  });

  test('paging exhausts after the demo pool', () {
    final body =
        call('/recommend/exploreRecom.json', params: {'offset': '32'});
    expect(body['data']['list'], isEmpty);
  });

  test('tag posts parse as PostListItem', () {
    final body = call('/newapi/tagPosts.json', params: {'offset': '8'});
    final list = body['data']['postList'] as List;
    for (final raw in list) {
      PostListItem.fromJson(Map<String, dynamic>.from(raw));
    }
  });

  test('search posts parse as SearchPost and TagInfo', () {
    final body = call('/newsearch/post.json', params: {'offset': '0'});
    for (final raw in body['data']['posts'] as List) {
      SearchPost.fromJson(Map<String, dynamic>.from(raw));
    }
    final all = call('/newsearch/v2/all.json', params: {'offset': '0'});
    for (final raw in all['data']['tags'] as List) {
      TagInfo.fromJson(Map<String, dynamic>.from(raw));
    }
    TagInfo.fromJson(
      Map<String, dynamic>.from(all['data']['tagRank'] as Map),
    );
  });

  test('collections parse as Collection', () {
    final body = call('/newsearch/collection.json', params: {'offset': '0'});
    for (final raw in body['data']['collections'] as List) {
      Collection.fromJson(Map<String, dynamic>.from(raw));
    }
  });

  test('search home entries parse', () {
    final guess = call('/newsearch/guess/keywords.json');
    for (final raw in guess['data']['guessKeywords'] as List) {
      GuessKeyword.fromJson(Map<String, dynamic>.from(raw));
    }
    final rank = call('/newapi/hotsearch/ranklist.json');
    for (final raw in rank['data']['rankList'] as List) {
      RankListItem.fromJson(Map<String, dynamic>.from(raw));
    }
    final sug = call('/newsearch/sug.json');
    for (final raw in sug['data']['items'] as List) {
      SearchSuggestItem.fromJson(Map<String, dynamic>.from(raw));
    }
  });

  test('comments parse as Comment', () {
    final hot = call('/comment/l1/hotnew.json', params: {'postId': '100001'});
    for (final raw in hot['data']['hotList'] as List) {
      Comment.fromJson(Map<String, dynamic>.from(raw));
    }
    final page = call('/comment/l2/page.json', params: {'postId': '100001'});
    for (final raw in page['data']['list'] as List) {
      Comment.fromJson(Map<String, dynamic>.from(raw));
    }
  });

  test('post detail parses as PostDetailData', () {
    final body = call('/oldapi/post/detail.api', params: {'postId': '100002'});
    expect(body['meta']['status'], 200);
    final posts = body['response']['posts'] as List;
    final parsed =
        PostDetailData.fromJson(Map<String, dynamic>.from(posts.first));
    expect(parsed.post, isNotNull);
  });

  test('timeline items parse as GrainPostItem', () {
    final body = call(
      '/timeline/app/getTrackItemListWithShare.json',
      params: {'showOffset': '0'},
    );
    for (final raw in body['data']['items'] as List) {
      GrainPostItem.fromJson(Map<String, dynamic>.from(raw));
    }
  });

  test('usercounts parses as AccountResponse with demo identity', () {
    final body = call('/v1.1/usercounts.api');
    expect(body['meta']['status'], 200);
    final account =
        AccountResponse.fromJson(Map<String, dynamic>.from(body['response']));
    expect(account.blogs, hasLength(1));
    expect(account.blogs.first.blogInfo?.blogId, DemoData.demoBlogId);
  });

  test('meInfo parses as MeInfoData', () {
    final body = call('/v1.1/meInfo.api');
    final me =
        MeInfoData.fromJson(Map<String, dynamic>.from(body['response']));
    expect(me.blogInfo.postCount, greaterThan(0));
  });

  test('unknown endpoints fall back to a safe dual envelope', () {
    final body = call('/unknown/endpoint.json');
    expect(body['code'], 0);
    expect(body['meta']['status'], 200);
  });
}
