import 'dart:convert';

/// 演示模式测试数据：全部按线上接口的 wire 格式（fromJson 可直接消费的
/// Map）构造，内容固定、图片走 picsum 固定 seed，保证每次演示观感一致。
class DemoData {
  static const int demoBlogId = 9527;

  static const List<String> _blogNames = [
    '星河漫步',
    '纸飞机与猫',
    '晚风信使',
    '山月手记',
    '橘子汽水铺',
  ];

  static const List<String> _titles = [
    '春日限定｜樱花祭典全记录',
    '水彩小景：窗台上的三色堇',
    '城市漫步指南｜老街巷的十个瞬间',
    '手作教程｜奶油胶发夹 DIY',
    '摄影笔记｜如何拍出通透的逆光人像',
    '读书摘抄｜把日子过成散文诗',
    '旅行手账｜海边小镇的两日一夜',
    '美食探店｜藏在弄堂里的糖水铺',
    '插画练习｜人物动态速写合集',
    '日常碎片｜今天也要好好生活',
  ];

  static const List<String> _digests = [
    '整理了一整个月的素材，终于把这组照片修完啦，分享给大家。',
    '步骤其实很简单，跟着做零基础也能一次成功，快试试看吧。',
    '把沿途遇见的风景和小店都记了下来，附上详细的路线图。',
    '这次尝试了新的配色方案，整体氛围感一下子就出来了。',
    '阴天的光线意外地柔和，是拍照的好时候。',
  ];

  static const List<String> _tags = ['演示', '测试数据', '摄影', '手作', '日常'];

  static String _cover(int seed, int w, int h) =>
      'https://picsum.photos/seed/loftify$seed/$w/$h';

  static String _avatar(int seed) =>
      'https://picsum.photos/seed/loftify-ava$seed/100/100';

  static int _count(int seed, int base) => base + (seed * 7) % 90;

  static Map<String, dynamic> demoBlogInfo(int seed) => {
        'bigAvaImg': _avatar(seed),
        'blogId': demoBlogId + seed,
        'blogName': 'demo${_blogNames[seed % _blogNames.length]}',
        'blogNickName': _blogNames[seed % _blogNames.length],
        'extraBits': 0,
        'selfIntro': '演示账号，数据均为测试数据',
        'isAuth': false,
        'isVerify': false,
      };

  static Map<String, dynamic> demoFullBlogInfo() => {
        ...demoBlogInfo(0),
        'blogId': demoBlogId,
        'auths': <String>[],
        'avatarBoxId': 0,
        'avatarBoxImage': '',
        'avatarBoxName': '',
        'avaUpdateTime': 0,
        'birthday': 0,
        'blogCreateTime': 1700000000000,
        'commentRank': 0,
        'gendar': 0,
        'homePageUrl': 'https://demo.lofter.com/',
        'imageDigitStamp': false,
        'imageProtected': false,
        'imageStamp': false,
        'isOriginalAuthor': true,
        'keyTag': '演示',
        'novisible': false,
        'postAddTime': 1700000000000,
        'postModTime': 1700000000000,
        'rssFileId': 0,
        'rssGenTime': 0,
        'signAuth': false,
      };

  static Map<String, dynamic> demoPostCount(int seed) => {
        'blogId': demoBlogId + seed,
        'favoriteCount': _count(seed, 12),
        'hotCount': _count(seed, 80),
        'postHot': _count(seed, 80),
        'reblogCount': _count(seed, 3),
        'responseCount': _count(seed, 5),
        'shareCount': _count(seed, 1),
        'subscribeCount': _count(seed, 2),
        'viewCount': _count(seed, 200),
      };

  static Map<String, dynamic> demoFirstImage(int seed) {
    final tall = seed.isEven;
    final (w, h) = tall ? (600, 800) : (800, 600);
    return {'oh': h, 'ow': w, 'orign': _cover(seed, w, h)};
  }

  /// `/recommend/exploreRecom.json`、`/newapi/tagPosts.json`、
  /// `/newsearch/*` 综合与图文结果共用的卡片结构。
  static Map<String, dynamic> demoPostListItem(int seed) => {
        'blogInfo': demoBlogInfo(seed),
        'favorite': seed.isOdd,
        'following': seed % 3 == 0,
        'groupInfo': null,
        'itemId': 100000 + seed,
        'itemType': 1,
        'postData': {
          'postCollection': null,
          'postCount': demoPostCount(seed),
          'postView': demoPostView(seed),
        },
        'reason': null,
        'reasonInfo': null,
        'recommendReport': {'algInfo': 'demo', 'recId': 'demo-rec-$seed'},
        'share': false,
        'showGift': false,
        'subscribe': false,
      };

  static Map<String, dynamic> demoPostView(int seed) => {
        'blogId': demoBlogId + seed,
        'digest': _digests[seed % _digests.length],
        'firstImage': demoFirstImage(seed),
        'forbidShare': 0,
        'id': 100000 + seed,
        'permalink': 'demo-post-$seed',
        'photoCount': 1 + seed % 3,
        'postPageUrl': 'https://demo.lofter.com/post/$seed',
        'previewUrl': null,
        'publishTime': 1735000000000 + seed * 3600000,
        'tagList': [_tags[seed % _tags.length], _tags[(seed + 1) % _tags.length]],
        'title': _titles[seed % _titles.length],
        'type': 2,
      };

  /// 帖子详情（`/oldapi/post/detail.api` → `response.posts[0].post`）。
  static Map<String, dynamic> demoPostDetail(int seed) => {
        'id': 100000 + seed,
        'blogId': demoBlogId + seed,
        'title': _titles[seed % _titles.length],
        'digest': _digests[seed % _digests.length],
        'content': '<p>${_digests[seed % _digests.length]}</p>'
            '<p>${_digests[(seed + 1) % _digests.length]}</p>',
        'type': 2,
        'permalink': 'demo-post-$seed',
        'blogPageUrl': 'https://demo.lofter.com/post/$seed',
        'photoCount': 1 + seed % 3,
        'publishTime': 1735000000000 + seed * 3600000,
        'tagList': [_tags[seed % _tags.length], _tags[(seed + 1) % _tags.length]],
        'firstImage': demoFirstImage(seed),
        'firstImageUrl': demoFirstImage(seed)['orign'],
        'firstSmallImageUrl': demoFirstImage(seed)['orign'],
        'photoLinks': jsonEncode([
          {
            'orign': _cover(seed, 600, 800),
            'raw': _cover(seed, 600, 800),
            'small': _cover(seed, 600, 800),
            'middle': _cover(seed, 600, 800),
            'rw': 600,
            'rh': 800,
            'ow': 600,
            'oh': 800,
          },
        ]),
        'photoCaptions': jsonEncode(['演示图片']),
        'postCount': demoPostCount(seed),
        'forbidShare': 0,
        'forbidPcomment': 0,
        'hot': _count(seed, 80),
        'isPublished': true,
        'valid': true,
        'publisherUserId': demoBlogId + seed,
        'rawTag': _tags[seed % _tags.length],
      };

  /// 时间线条目（`/timeline/app/getTrackItemListWithShare.json`）。
  static Map<String, dynamic> demoGrainPostItem(int seed) => {
        'followed': seed % 3 == 0,
        'liked': seed.isOdd,
        'opTime': 1735000000000 + seed * 3600000,
        'postData': {
          'blogInfo': demoBlogInfo(seed),
          'postCollection': null,
          'postCountView': demoPostCount(seed),
          'postExt': null,
          'postView': demoPostDetail(seed),
        },
        'shared': false,
        'showFullText': true,
        'subscribed': false,
        'shareInfo': null,
      };

  /// 评论条目（`/comment/l1/*`、`/comment/l2/*`）。
  static Map<String, dynamic> demoComment(int seed, {int postId = 100000}) => {
        'blogId': demoBlogId + seed,
        'id': 500000 + seed,
        'postId': postId,
        'content': _digests[seed % _digests.length],
        'ipLocation': '浙江',
        'l2Count': seed % 3,
        'likeCount': _count(seed, 4),
        'liked': seed.isEven,
        'publishTime': 1735000000000 + seed * 600000,
        'top': 0,
        'publisherBlogInfo': demoBlogInfo(seed),
      };

  /// 标签信息（搜索结果、相关标签）。
  static Map<String, dynamic> demoTagInfo(int seed) => {
        'imageUrl': _cover(seed + 500, 400, 400),
        'joinCount': _count(seed, 1200),
        'recommendReport': {'algInfo': 'demo', 'recId': 'demo-tag-$seed'},
        'subscribed': seed.isEven,
        'tagName': _tags[seed % _tags.length],
        'tagType': 1,
      };

  /// 搜索「图文」结果条目。
  static Map<String, dynamic> demoSearchPost(int seed) => {
        'blogId': demoBlogId + seed,
        'blogInfo': demoBlogInfo(seed),
        'digest': _digests[seed % _digests.length],
        'firstImage': demoFirstImage(seed),
        'forbidShare': 0,
        'id': 100000 + seed,
        'itemType': 1,
        'permalink': 'demo-post-$seed',
        'photoCount': 1 + seed % 3,
        'postCount': demoPostCount(seed),
        'postPageUrl': 'https://demo.lofter.com/post/$seed',
        'previewUrl': '',
        'publishTime': 1735000000000 + seed * 3600000,
        'recommendReport': {'algInfo': 'demo', 'recId': 'demo-rec-$seed'},
        'recReason': '演示推荐',
        'tagList': [_tags[seed % _tags.length]],
        'title': _titles[seed % _titles.length],
        'type': 2,
      };

  /// 搜索「合集」结果条目。
  static Map<String, dynamic> demoCollection(int seed) => {
        'blogId': demoBlogId + seed,
        'blogName': 'demo$seed',
        'collectionType': 0,
        'coverUrl': _cover(seed + 700, 600, 800),
        'id': 700000 + seed,
        'lastPublishTime': 1735000000000 + seed * 3600000,
        'name': '${_titles[seed % _titles.length]}·合集',
        'postCount': 8 + seed % 20,
        'rankContent': '',
        'rankUrl': '',
        'subscribed': seed.isEven,
        'tags': [_tags[seed % _tags.length]],
        'top': false,
      };

  /// 搜索首页「猜你想搜」条目。
  static Map<String, dynamic> demoGuessKeyword(int seed) => {
        'keyword': _tags[seed % _tags.length],
        'recommendReport': {'algInfo': 'demo', 'recId': 'demo-guess-$seed'},
        'type': 0,
      };

  /// 搜索首页热榜条目。
  static Map<String, dynamic> demoRankItem(int seed) => {
        'blogId': demoBlogId + seed,
        'icon': '',
        'img': _cover(seed + 300, 400, 300),
        'interactionCount': _count(seed, 300),
        'isAuth': false,
        'isVerify': false,
        'postDigest': _digests[seed % _digests.length],
        'postId': 100000 + seed,
        'postType': 2,
        'pv': _count(seed, 2000),
        'resource': 1,
        'score': '${8 + seed % 2}.${seed % 10}',
        'title': _titles[seed % _titles.length],
        'trend': 1,
        'url': 'https://demo.lofter.com/post/$seed',
      };

  /// 搜索建议条目（type 1 = 标签）。
  static Map<String, dynamic> demoSuggestItem(int seed) => {
        'type': 1,
        'recomReason': '演示推荐',
        'tagInfo': demoTagInfo(seed),
      };

  /// `/v1.1/usercounts.api` → `response`（AccountResponse 严格解析，
  /// 所有非空字段都必须给出；注意 `ak_aos`/`ak_ios`/`main_blog_id`/
  /// `user_id` 是下划线 wire keys）。
  static Map<String, dynamic> demoAccountResponse() => {
        'acceptGiftFlag': 0,
        'accountBindTip': 0,
        'ak_aos': '',
        'ak_ios': '',
        'anchorOpen': false,
        'appImageProtection': false,
        'appImageStamp': false,
        'appIndexActActive': false,
        'appVideoProtect': false,
        'archiveSettings': <String, dynamic>{},
        'authApplyUrl': '',
        'blogCovers': <String, dynamic>{},
        'blogs': [
          {
            'blogId': demoBlogId,
            'blogInfo': demoFullBlogInfo(),
            'id': 1,
            'joinTime': 1700000000000,
            'role': 0,
            'userId': demoBlogId,
          },
        ],
        'checkVerifyBlog': false,
        'counts': <dynamic>[],
        'curtime': 1735000000000,
        'defaultAuditTime': <dynamic>[
          {'auditTime': 0, 'endTime': 0, 'startTime': 0},
        ],
        'domains': <String, dynamic>{},
        'email': '',
        'giftAccountStatus': 0,
        'giftAccountType': 0,
        'hasNewSelection': false,
        'homeimageurl': '',
        'imgProtectedType': 0,
        'isTradePayAuthor': false,
        'liveUrl': '',
        'locationflag': 0,
        'loftInToken': '',
        'loginType': 0,
        'main_blog_id': '$demoBlogId',
        'manageTags': <String>['演示', '测试数据'],
        'msgCountUpdateTime': 0,
        'needShowAd': false,
        'newFollowingUAppCount': 0,
        'newfriendcount': 0,
        'noticeCountUpdateTime': 0,
        'openShortFilm': '',
        'pushVersion': '',
        'randomrecoms': {
          'blogs': <String>[],
          'tags': <String>[_tags[0], _tags[1]],
        },
        'recConf': {
          'joinSwitchs': <dynamic>[
            {'scene': 'demo', 'status': 1, 'viewTime': 0},
          ],
        },
        'recommendSearchKeys': <String>[_tags[0], _tags[2]],
        'scoreMallUrl': '',
        'shortFilmTagMap': '',
        'showAuthApply': false,
        'showGiftAct': false,
        'showGiftChangeStatus': 0,
        'showGuide': 0,
        'showLoftIn': false,
        'showLuckyBoy': false,
        'showScoreMall': false,
        'showSkip': 0,
        'siteType': 0,
        'subscribeCollectionCount': 0,
        'subscribeRedShow': false,
        'thirdpartyApps': <String, dynamic>{},
        'tipsetting': {
          'benefitOrder': 0,
          'dailyTipCount': 0,
          'followerCount': '0',
          'followMsg': '',
          'messageCount': '0',
          'noticeMsg': '',
          'orderMsg': '',
          'responseCount': '0',
          'specialFollow': 0,
          'yinOrder': 0,
        },
        'unReadEventsCount': 0,
        'usedToYouthMode': false,
        'user_id': '$demoBlogId',
        'userGrainConfigInfo': {'grainAddLimit': 10, 'grainPostLimit': 10},
        'userStatistic': <String, dynamic>{},
        'watermarkActivities': <String>[],
        'webImageStamp': false,
        'whiteNoiseMusicList': <dynamic>[],
        'youthMode': false,
      };

  /// `/v1.1/meInfo.api` → `response`（MeInfoData 严格解析）。
  static Map<String, dynamic> demoMeInfo() => {
        'askOpen': false,
        'blogInfo': {
          'attentionCount': 28,
          'avatarBoxImage': '',
          'followerCount': 156,
          'hot': demoMeInfoCount(30),
          'hotDelta': demoMeInfoCount(7),
          'likeCount': 892,
          'newSubscribeCount': 3,
          'postCount': 42,
          'questionCount': 0,
          'shareCount': 12,
          'signAuth': false,
          'subscribeCollectionCount': 5,
          'subscribeCount': 17,
          'subscribeRedShow': false,
        },
        'collectionCount': 5,
        'enableReward': 0,
        'feedback': '',
        'feedbackUrl': '',
        'gameImage': '',
        'gameOpen': 0,
        'gameTxt': '',
        'gameUrl': '',
        'kefuOpen': 0,
        'signAuthUrl': '',
        'signProtocol': '',
        'yinDefaultContent': '',
        'yinInfo': null,
      };

  static Map<String, dynamic> demoMeInfoCount(int base) => {
        'endDay': base,
        'favoriteCount': base * 3,
        'hotCount': base * 30,
        'reblogCount': base,
        'shareCount': base ~/ 2,
        'subscribeCount': base,
        'tagChatFavoriteCount': 0,
      };
}
