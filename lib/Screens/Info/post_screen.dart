import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/history_response.dart';
import 'package:loftify/Screens/Info/nested_mixin.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Models/post_detail_response.dart';
import '../../Utils/enums.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/Navigation/loftify_glass_navigation_bar.dart';
import '../../Widgets/PostItem/common_info_post_item_builder.dart';
import '../../Widgets/PostItem/loftify_post_archive_grid.dart';
import '../../l10n/l10n.dart';

class PostScreen extends StatefulWidgetForNested {
  PostScreen({
    super.key,
    this.infoMode = InfoMode.me,
    this.scrollController,
    this.blogId,
    this.blogName,
    super.nested = false,
    super.refreshListenable,
    super.refreshId = 'article',
  }) {
    if (infoMode == InfoMode.other) {
      assert(blogName != null);
    }
  }

  final InfoMode infoMode;
  final int? blogId;
  final String? blogName;
  final ScrollController? scrollController;

  static const String routeName = "/info/post";

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends BaseDynamicState<PostScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        NestedRefreshSignalMixin<PostScreen> {
  @override
  bool get wantKeepAlive => true;
  PostDetailData? _topPost;
  final List<PostDetailData> _postList = [];
  List<ArchiveData> _archiveDataList = [];
  bool _loading = false;
  final EasyRefreshController _refreshController = EasyRefreshController();
  bool _noMore = false;
  InitPhase _initPhase = InitPhase.haveNotConnected;

  @override
  void initState() {
    super.initState();
    bindNestedRefreshSignal(() {
      _refreshController.callRefresh(
        overOffset: 28,
        duration: const Duration(milliseconds: 140),
      );
    });
    if (widget.nested) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onRefresh();
      });
    } else {
      _initPhase = InitPhase.successful;
      setState(() {});
    }
  }

  @override
  void dispose() {
    unbindNestedRefreshSignal();
    _refreshController.dispose();
    super.dispose();
  }

  _fetchLike({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) _noMore = false;
    _loading = true;
    int offset = 0;
    if (refresh) {
      offset = 0;
    } else {
      if (_archiveDataList.isNotEmpty && _archiveDataList[0].isTop) {
        offset = _postList.length - _archiveDataList[0].count;
      }
    }
    if (_initPhase != InitPhase.successful) {
      _initPhase = InitPhase.connecting;
      setState(() {});
    }
    return await HiveUtil.getUserInfo().then((blogInfo) async {
      String blogName = widget.infoMode == InfoMode.me
          ? blogInfo!.blogName
          : widget.blogName!;
      int blogId =
          widget.infoMode == InfoMode.me ? blogInfo!.blogId : widget.blogId!;
      return await UserApi.getPostList(
        blogName: blogName,
        blogId: blogId,
        offset: offset,
      ).then((value) {
        try {
          if (value['meta']['status'] != 200) {
            IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
            return IndicatorResult.fail;
          } else {
            if (value['response']['archives'] != null) {
              _archiveDataList = [];
              List<ArchiveItem> archiveItems = [];
              List<dynamic> t = value['response']['archives'];
              for (var e in t) {
                archiveItems.add(ArchiveItem.fromJson(e));
              }
              for (var e in archiveItems) {
                for (var item in e.monthCount) {
                  if (item > 0) {
                    int month = e.monthCount.indexOf(item);
                    _archiveDataList.add(ArchiveData(
                      desc: appLocalizations.yearAndMonth(month + 1, e.year),
                      count: item,
                      endTime: 0,
                      startTime: 0,
                    ));
                  }
                }
              }
              _archiveDataList.sort((a, b) => b.desc.compareTo(a.desc));
            }
            List<PostDetailData> tmp = [];
            if (refresh) _postList.clear();
            for (var e in (value['response']['posts'] as List)) {
              if (e != null &&
                  _postList.indexWhere(
                          (element) => element.post!.id == e['post']['id']) ==
                      -1) {
                tmp.add(PostDetailData.fromJson(e));
              }
            }
            _postList.addAll(tmp);
            if (value['response']['topPost'] != null) {
              _topPost = PostDetailData.fromJson(value['response']['topPost']);
              _archiveDataList.insert(
                0,
                ArchiveData(
                  desc: appLocalizations.pin,
                  count: 1,
                  endTime: 0,
                  startTime: 0,
                  isTop: true,
                ),
              );
              if ((_postList.isNotEmpty &&
                      _postList[0].post!.id != _topPost!.post!.id) ||
                  _postList.isEmpty) {
                _postList.insert(0, _topPost!);
              }
            }
            if (mounted) setState(() {});
            _initPhase = InitPhase.successful;
            if (tmp.isEmpty && !refresh) {
              _noMore = true;
              return IndicatorResult.noMore;
            } else {
              return IndicatorResult.success;
            }
          }
        } catch (e, t) {
          _initPhase = InitPhase.failed;
          ILogger.error("Failed to load post list", e, t);
          if (mounted) IToast.showTop(appLocalizations.loadFailed);
          return IndicatorResult.fail;
        } finally {
          if (mounted) setState(() {});
          _loading = false;
        }
      });
    });
  }

  _onRefresh() async {
    return await _fetchLike(refresh: true);
  }

  _onLoad() async {
    return await _fetchLike();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: widget.infoMode == InfoMode.me
          ? ChewieTheme.getBackground(context)
          : Colors.transparent,
      appBar: widget.infoMode == InfoMode.me ? _buildAppBar() : null,
      body: _buildBody(),
    );
  }

  _buildBody() {
    switch (_initPhase) {
      case InitPhase.connecting:
        return LoadingWidget(background: Colors.transparent);
      case InitPhase.failed:
        return CustomErrorWidget(
          onTap: _onRefresh,
        );
      case InitPhase.successful:
        return EasyRefresh.builder(
          header: widget.nested ? buildNestedRefreshHeader() : null,
          refreshOnStart: !widget.nested,
          controller: _refreshController,
          onRefresh: _onRefresh,
          onLoad: _noMore ? null : _onLoad,
          triggerAxis: Axis.vertical,
          childBuilder: (context, physics) {
            return _archiveDataList.isNotEmpty
                ? _buildNineGridGroup(physics)
                : EmptyPlaceholder(
                    text: appLocalizations.noArticle,
                    physics: physics,
                    shrinkWrap: false,
                  );
          },
        );
      default:
        return Container();
    }
  }

  Widget _buildNineGridGroup(ScrollPhysics physics) {
    // Group headers and tiles build on demand — materializing every archive
    // tile up front stalled long archives (same sliver grid as like_screen).
    final groups = <({String title, int start, int count})>[];
    var startIndex = 0;
    for (final e in _archiveDataList) {
      if (startIndex >= _postList.length) break;
      if (e.count == 0) continue;
      int count = e.count;
      if (_postList.length < startIndex + count) {
        count = _postList.length - startIndex;
      }
      groups.add((
        title: appLocalizations.descriptionWithPostCount(
            e.desc, e.count.toString()),
        start: startIndex,
        count: count,
      ));
      startIndex += e.count;
    }
    return CustomScrollView(
      controller: widget.scrollController,
      physics: physics,
      slivers: [
        for (final group in groups) ...[
          SliverToBoxAdapter(
            child: ItemBuilder.buildTitle(
              context,
              title: group.title,
              topMargin: 16,
              bottomMargin: 0,
            ),
          ),
          LoftifyPostArchiveSliverGrid(
            padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
            itemCount: group.count,
            itemBuilder: (context, index, tileExtent) {
              final trueIndex = group.start + index;
              return CommonInfoItemBuilder.buildNineGridPostItem(
                context,
                _postList[trueIndex],
                wh: tileExtent,
              );
            },
          ),
        ],
        SliverToBoxAdapter(
          child: SizedBox(
            height: 20 + LoftifyGlassNavigationBar.contentBottomPadding(context),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ResponsiveAppBar(
      showBack: true,
      title: appLocalizations.myPosts,
    );
  }
}
