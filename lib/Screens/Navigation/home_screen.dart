import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/recommend_api.dart';
import 'package:loftify/Widgets/PostItem/recommend_flow_item_builder.dart';

import '../../Models/recommend_response.dart';
import '../../Theme/loftify_design_theme.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/paged_data_controller.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';

int krefreshTimeout = 300;

typedef _ExploreCursor = ({int offset, int page, int feed});

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.scrollController,
  });

  final ScrollController? scrollController;

  static const String routeName = "/nav/home";

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends BaseDynamicState<HomeScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        ScrollToHideMixin,
        BottomNavgationMixin {
  @override
  bool get wantKeepAlive => true;
  int lastRefreshTime = 0;
  final EasyRefreshController _refreshController = EasyRefreshController();
  late final ScrollController _scrollController =
      widget.scrollController ?? ScrollController();
  late final PagedDataController<PostListItem, int, _ExploreCursor, void>
      _pagingController;
  late AnimationController _refreshRotationController;
  final ScrollToHideController _scrollToHideController =
      ScrollToHideController();

  refresh() {
    _refreshController.callRefresh();
  }

  @override
  void initState() {
    super.initState();
    _refreshRotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pagingController = PagedDataController(
      initialCursor: (offset: 0, page: 0, feed: 0),
      keyOf: (item) => item.postData?.postView.id ?? item.itemId,
      loader: _loadExplorePage,
      onError: (error, stackTrace) {
        ILogger.error(
            'Failed to load explore recommendations', error, stackTrace);
        if (!mounted) return;
        IToast.showTop(
          error is PagedDataException && StringUtil.isNotEmpty(error.message)
              ? error.message
              : appLocalizations.loadFailed,
        );
      },
    );
    // 分页通知只重建列表区（build 中的 ListenableBuilder），
    // 不再让 Scaffold/AppBar/悬浮按钮跟着每次加载重建。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) panelScreenState?.refreshScrollControllers();
    });
  }

  Future<PagedDataPage<PostListItem, _ExploreCursor, void>> _loadExplorePage(
    _ExploreCursor cursor,
    bool refresh,
  ) async {
    final page = refresh ? 1 : cursor.page + 1;
    final feed = refresh ? 0 : cursor.feed + 1;
    final value = await RecommendApi.getExploreRecomend(
      offset: refresh ? 0 : cursor.offset,
      page: page,
      feed: feed,
    );
    final code = (value['code'] as num?)?.toInt();
    if (code == 4009) {
      return PagedDataPage(
        items: const [],
        nextCursor: cursor,
        hasMore: false,
      );
    }
    if (code != 0) {
      throw PagedDataException(value['msg']?.toString() ?? '');
    }

    final data = value['data'];
    if (data is! Map) {
      throw const PagedDataException('');
    }
    final rawItems = data['list'] is List
        ? List<dynamic>.from(data['list'] as List)
        : const <dynamic>[];
    final items = <PostListItem>[];
    for (final rawItem in rawItems) {
      try {
        if (rawItem is Map) {
          items.add(PostListItem.fromJson(
            Map<String, dynamic>.from(rawItem),
          ));
        }
      } catch (error, stackTrace) {
        ILogger.error('Skipped malformed explore card', error, stackTrace);
      }
    }
    final nextOffset = (data['offset'] as num?)?.toInt() ?? cursor.offset;
    return PagedDataPage(
      items: items,
      nextCursor: (offset: nextOffset, page: page, feed: feed),
      hasMore: rawItems.isNotEmpty,
    );
  }

  /// Cards with an index below this window play the entrance animation; it
  /// resets on refresh and closes shortly after the first page settles.
  int _entranceWindow = 12;

  void _scheduleEntranceWindowClose() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _entranceWindow != 0) {
        setState(() => _entranceWindow = 0);
      }
    });
  }

  Future<IndicatorResult> _onRefresh() async {
    if (mounted && _entranceWindow == 0) {
      setState(() => _entranceWindow = 12);
    }
    final result = await _pagingController.refresh();
    _scheduleEntranceWindowClose();
    return result;
  }

  Future<IndicatorResult> _onLoad() => _pagingController.load();

  @override
  void dispose() {
    _pagingController.dispose();
    _refreshController.dispose();
    _refreshRotationController.dispose();
    if (widget.scrollController == null) _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final design = context.design;
    return Scaffold(
      backgroundColor: design.colors.page,
      appBar: ResponsiveAppBar(
        title: appLocalizations.home,
        titleLeftMargin: 15,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth;
          final centeredInset =
              ((viewportWidth - design.grid.maximumContentWidth) / 2)
                  .clamp(0.0, double.infinity);
          final pageInset = design.grid.denseFeedPagePaddingFor(viewportWidth);
          final horizontalInset = centeredInset + pageInset;
          final gutter = design.grid.gutterFor(viewportWidth);

          return Stack(
            children: [
              // Scoped rebuild: paging notifications rebuild only the feed
              // scroll view, not the Scaffold, app bar or floating buttons.
              ListenableBuilder(
                listenable: _pagingController,
                builder: (context, _) => EasyRefresh(
                  refreshOnStart: true,
                  controller: _refreshController,
                  onRefresh: _onRefresh,
                  onLoad: _pagingController.noMore ? null : _onLoad,
                  child: CustomScrollView(
                    controller: _scrollController,
                    // Pre-building a whole extra viewport of waterfall
                    // cards keeps large lists alive for no visible gain;
                    // a fixed window covers several rows of cards.
                    cacheExtent:
                        MediaQuery.sizeOf(context).height.clamp(0.0, 480.0),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.only(
                          top: 8,
                          left: horizontalInset,
                          right: horizontalInset,
                        ),
                        sliver: SliverWaterfallFlow(
                          gridDelegate:
                              SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                            mainAxisSpacing: gutter,
                            crossAxisSpacing: gutter,
                            maxCrossAxisExtent:
                                design.grid.maximumDenseCardExtent,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) {
                              final item = _pagingController.items[index];
                              return KeyedSubtree(
                                key: ValueKey(
                                  'explore-${item.postData?.postView.id ?? item.itemId}',
                                ),
                                child: _FeedEntranceItem(
                                  // Entrance plays only for the first
                                  // screenful right after a load/refresh;
                                  // scrolled-back or paginated cards appear
                                  // without re-animating.
                                  animate: index < _entranceWindow,
                                  delayMs: index * 16,
                                  child: RecommendFlowItemBuilder
                                      .buildWaterfallFlowPostItem(
                                    context,
                                    item,
                                    showMoreButton: true,
                                  ),
                                ),
                              );
                            },
                            childCount: _pagingController.items.length,
                            addAutomaticKeepAlives: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: horizontalInset,
                bottom: ResponsiveUtil.isLandscapeLayout() ||
                        ResponsiveUtil.isTabletLayout()
                    ? design.spacing.xl
                    : 76,
                child: ScrollToHide.multi(
                  controller: _scrollToHideController,
                  scrollControllers: [_scrollController],
                  hideDirection: Axis.vertical,
                  child: _buildFloatingButtons(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void scrollToTopAndRefresh() {
    int nowTime = DateTime.now().millisecondsSinceEpoch;
    if (lastRefreshTime == 0 || (nowTime - lastRefreshTime) > krefreshTimeout) {
      lastRefreshTime = nowTime;
      if (_scrollController.offset > MediaQuery.sizeOf(context).height) {
        _scrollController
            .animateTo(0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut)
            .then((_) {
          _refreshController.callRefresh();
        });
      } else {
        _refreshController.callRefresh();
      }
    }
  }

  _buildFloatingButtons() {
    return ResponsiveUtil.isLandscapeLayout() ||
            ResponsiveUtil.isTabletLayout()
        ? Column(
            children: [
              ShadowIconButton(
                icon: RotationTransition(
                  turns: Tween(begin: 0.0, end: 1.0)
                      .animate(_refreshRotationController),
                  child: const ChewieIcon(LoftifyIcons.refresh),
                ),
                onTap: () async {
                  refresh();
                },
              ),
              const SizedBox(height: 10),
              ShadowIconButton(
                icon: const ChewieIcon(LoftifyIcons.scrollTop),
                onTap: () {
                  scrollToTop();
                },
              ),
            ],
          )
        : emptyWidget;
  }

  void scrollToTop() {
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  void scrollToTopOrRefresh() {
    if (_scrollController.offset > 30) {
      scrollToTop();
    } else {
      _refreshController.callRefresh();
    }
  }

  @override
  List<ScrollController> getScrollControllers() {
    return [_scrollController];
  }

  @override
  FutureOr onTapBottomNavigation() {
    scrollToTopOrRefresh();
  }
}

/// First-screen entrance: a quick fade with a small upward rise, staggered
/// per card. Plays once when the element is first built with [animate] set;
/// later rebuilds and paginated cards are passed through untouched, and
/// reduced-motion users skip straight to the resting state.
class _FeedEntranceItem extends StatefulWidget {
  const _FeedEntranceItem({
    required this.animate,
    required this.delayMs,
    required this.child,
  });

  final bool animate;
  final int delayMs;
  final Widget child;

  @override
  State<_FeedEntranceItem> createState() => _FeedEntranceItemState();
}

class _FeedEntranceItemState extends State<_FeedEntranceItem>
    with SingleTickerProviderStateMixin {
  static const Duration _entranceDuration = Duration(milliseconds: 240);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _entranceDuration,
  );

  @override
  void initState() {
    super.initState();
    if (!widget.animate) {
      _controller.value = 1;
      return;
    }
    // Once finished, drop the wrappers entirely: later rebuilds (scrolling
    // back, paging) render the plain child with no lingering saveLayer.
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.maybeOf(context)?.disableAnimations == true) {
        _controller.value = 1;
        return;
      }
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _controller.forward();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isCompleted || _controller.value == 1) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final curved = Curves.easeOutCubic.transform(_controller.value);
        return Opacity(
          opacity: curved,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - curved)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
