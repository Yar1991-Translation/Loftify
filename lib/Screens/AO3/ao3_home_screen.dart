import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Api/ao3_api.dart';
import '../../Api/ao3_feed_api.dart';
import '../../Models/ao3_feed_entry.dart';
import '../../Theme/loftify_design_theme.dart';
import '../../Utils/ao3_store.dart';
import '../../Utils/ao3_tags.dart';
import '../../Utils/app_provider.dart';
import '../../Widgets/Design/loftify_controls.dart';
import '../../Widgets/Design/loftify_state_view.dart';
import '../../Widgets/Design/loftify_surfaces.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/Navigation/loftify_glass_navigation_bar.dart';
import '../Setting/ao3_setting_screen.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';
import 'ao3_library_screen.dart';
import 'ao3_reader_screen.dart';
import 'ao3_theme.dart';
import 'ao3_search_screen.dart';
import 'ao3_work_card.dart';

/// The AO3 start page: local shelf and followed-tag listings first,
/// network only to refresh what is stale.
class Ao3HomeScreen extends StatefulWidget {
  const Ao3HomeScreen({super.key, this.scrollController});

  final ScrollController? scrollController;

  static const String routeName = "/nav/ao3";

  @override
  State<Ao3HomeScreen> createState() => Ao3HomeScreenState();
}

class Ao3HomeScreenState extends BaseDynamicState<Ao3HomeScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        ScrollToHideMixin,
        BottomNavgationMixin {
  @override
  bool get wantKeepAlive => true;

  final EasyRefreshController _refreshController = EasyRefreshController();
  late final ScrollController _scrollController =
      widget.scrollController ?? ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Ao3LibraryEntry> _continueReading = const [];
  Map<String, List<Ao3FeedEntry>> _feeds = const {};
  List<String> _followed = const [];
  String _activeTag = '';
  String? _error;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadLocal();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) panelScreenState?.refreshScrollControllers();
      _refreshIfStale();
    });
  }

  void _loadLocal() {
    final followed = Ao3Tags.followed();
    final entries = Ao3Store().entries();
    final started = entries
        .where((e) =>
            e.lastReadAtMs > e.savedAtMs || e.chapterIndex > 1)
        .toList()
      ..sort((a, b) => b.lastReadAtMs.compareTo(a.lastReadAtMs));
    setState(() {
      _followed = followed;
      _continueReading = started;
      _feeds = {
        for (final tag in followed) tag: Ao3Tags.readFeed(tag)?.entries ?? const [],
      };
    });
  }

  List<Ao3FeedEntry> get _visibleFeed {
    if (_activeTag.isNotEmpty) return _feeds[_activeTag] ?? const [];
    final merged = <Ao3FeedEntry>[
      for (final entries in _feeds.values) ...entries,
    ];
    final seen = <int>{};
    merged.retainWhere((entry) => seen.add(entry.workId));
    merged.sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
    return merged;
  }

  bool _hasStaleCache() {
    final tags = _activeTag.isEmpty ? _followed : [_activeTag];
    if (tags.isEmpty) return false;
    return tags.any((tag) => !Ao3Tags.isFresh(Ao3Tags.readFeed(tag)));
  }

  Future<void> _refreshIfStale() async {
    if (_hasStaleCache()) await _refresh();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    final tags = _activeTag.isEmpty ? _followed : [_activeTag];
    if (tags.isEmpty) return;
    setState(() {
      _refreshing = true;
      _error = null;
    });
    String? firstError;
    for (final tag in tags) {
      try {
        final entries = await Ao3FeedApi.fetchTagWorks(tag);
        await Ao3Tags.writeFeed(tag, entries);
      } on Ao3Exception catch (error) {
        firstError ??= _messageFor(error, tag);
      } catch (error, stack) {
        ILogger.error("Failed to refresh AO3 feed", error, stack);
        firstError ??= appLocalizations.ao3FeedUpdateFailed;
      }
    }
    if (!mounted) return;
    setState(() {
      _refreshing = false;
      _error = firstError;
      _followed = Ao3Tags.followed();
      final keys = _activeTag.isEmpty ? _followed : [_activeTag];
      _feeds = {
        for (final tag in keys) tag: Ao3Tags.readFeed(tag)?.entries ?? const [],
      };
    });
  }

  /// The banner names the tag that failed: a followed tag can disappear on
  /// AO3, and the user can only unfollow what the message identifies.
  String _messageFor(Ao3Exception error, [String tag = '']) {
    final suffix = tag.isEmpty ? '' : '（' + tag + '）';
    switch (error.failure) {
      case Ao3Failure.notFound:
        return appLocalizations.ao3TagNotFound + suffix;
      case Ao3Failure.blocked:
        return appLocalizations.ao3Blocked + suffix;
      case Ao3Failure.disabled:
        return appLocalizations.ao3Disabled;
      case Ao3Failure.timeout:
      case Ao3Failure.network:
      case Ao3Failure.loginRequired:
      case Ao3Failure.notAWork:
        return appLocalizations.ao3NetworkFailed + suffix;
    }
  }

  void _activateTag(String tag) {
    setState(() => _activeTag = tag);
    _loadLocal();
    _refreshIfStale();
  }

  Future<void> _followTag(String tag) async {
    final normalized = tag.trim();
    if (normalized.isEmpty) return;
    CustomLoadingDialog.showLoading(title: appLocalizations.loading);
    try {
      final entries = await Ao3FeedApi.fetchTagWorks(normalized);
      await Ao3Tags.writeFeed(normalized, entries);
      await Ao3Tags.follow(normalized);
      if (!mounted) return;
      setState(() => _activeTag = normalized);
      _loadLocal();
    } on Ao3Exception catch (error) {
      if (!mounted) return;
      IToast.showTop(_messageFor(error));
    } catch (error, stack) {
      ILogger.error("Failed to follow AO3 tag", error, stack);
      if (mounted) IToast.showTop(appLocalizations.ao3FeedUpdateFailed);
    } finally {
      await CustomLoadingDialog.dismissLoading();
    }
  }

  void _confirmUnfollow(String tag) {
    DialogBuilder.showConfirmDialog(
      context,
      title: appLocalizations.ao3Unfollow,
      message: appLocalizations.ao3UnfollowMessage(tag),
      confirmButtonText: appLocalizations.confirm,
      cancelButtonText: appLocalizations.cancel,
      onTapConfirm: () async {
        await Ao3Tags.unfollow(tag);
        if (!mounted) return;
        if (_activeTag == tag) setState(() => _activeTag = '');
        _loadLocal();
      },
    );
  }

  /// Manage sheet: followed tags are deletable rows (a chip with no visible
  /// removal affordance was the complaint), and suggestions come from the
  /// works already cached on this device.
  void _openManageSheet() {
    // Reading the suggestions decodes the cached works, so it happens once
    // per sheet instead of on every sheet rebuild (following a tag rebuilds
    // the sheet, and the list already filters followed tags at render time).
    final suggestions = Ao3Tags.suggestions();
    BottomSheetBuilder.showBottomSheet(
      context,
      (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.design.spacing.xl),
          child: StatefulBuilder(builder: (sheetInnerContext, sheetSetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appLocalizations.ao3ManageTags,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: context.design.spacing.lg),
                // Long tag lists must stay reachable: the sheet scrolls
                // instead of clipping whatever runs past the screen.
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                Text(
                  appLocalizations.ao3FollowedTags,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                SizedBox(height: context.design.spacing.sm),
                if (_followed.isEmpty)
                  Text(
                    appLocalizations.ao3NoTagSuggestions,
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  ..._followed.map(
                    (tag) => Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: context.design.spacing.xs,
                            ),
                            child: Text(
                              tag,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                        ChewieIconButton(
                          icon: LoftifyIcons.delete,
                          tooltip: appLocalizations.ao3Unfollow,
                          onPressed: () async {
                            await Ao3Tags.unfollow(tag);
                            if (!mounted) return;
                            if (_activeTag == tag) {
                              setState(() => _activeTag = '');
                            }
                            _loadLocal();
                            sheetSetState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: context.design.spacing.lg),
                Text(
                  appLocalizations.ao3FromYourWorks,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                SizedBox(height: context.design.spacing.sm),
                if (suggestions.isEmpty)
                  Text(
                    appLocalizations.ao3NoTagSuggestions,
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  Wrap(
                    spacing: context.design.spacing.sm,
                    runSpacing: context.design.spacing.sm,
                    children: [
                      for (final tag in suggestions)
                        if (!_followed.contains(tag))
                          LoftifyTag(
                            label: tag,
                            maxWidth: 200,
                            onPressed: () async {
                              await _followTag(tag);
                              if (sheetContext.mounted) sheetSetState(() {});
                            },
                          ),
                    ],
                  ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
      preferMinWidth: 400,
      responsive: true,
    );
  }

  @override
  List<ScrollController> getScrollControllers() {
    return [_scrollController];
  }

  @override
  FutureOr<void> onTapBottomNavigation() {
    // The shelf may have changed while another tab was open (works deleted,
    // new reads) — refresh the local view before doing anything else.
    _loadLocal();
    if (_scrollController.hasClients && _scrollController.offset > 0) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _refreshController.callRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final design = context.design;
    return Ao3Theme(
      child: Scaffold(
      backgroundColor: design.colors.page,
      appBar: ResponsiveAppBar(
        title: appLocalizations.ao3Home,
        titleLeftMargin: 15,
        actions: [
          ChewieIconButton(
            icon: LoftifyIcons.book,
            tooltip: appLocalizations.ao3Library,
            onPressed: () => RouteUtil.pushPanelCupertinoRoute(
              context,
              const Ao3LibraryScreen(),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth;
          final centeredInset =
              ((viewportWidth - design.grid.maximumContentWidth) / 2)
                  .clamp(0.0, double.infinity);
          final pageInset =
              design.grid.denseFeedPagePaddingFor(viewportWidth);
          final inset = centeredInset + pageInset;
          return EasyRefresh(
            controller: _refreshController,
            onRefresh: _refresh,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(inset, 8, inset, 0),
                    child: ItemBuilder.buildSearchBar(
                      context: context,
                      hintText: appLocalizations.ao3SearchWorksHint,
                      controller: _searchController,
                      onSubmitted: (value) {
                        final query = value?.toString().trim() ?? "";
                        if (query.isEmpty) return;
                        _searchController.clear();
                        RouteUtil.pushPanelCupertinoRoute(
                          context,
                          Ao3SearchScreen(initialQuery: query),
                        );
                      },
                    ),
                  ),
                ),
                if (_continueReading.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _continueSection(context, inset),
                  ),
                SliverToBoxAdapter(
                  child: _tagRow(context, inset),
                ),
                SliverToBoxAdapter(
                  child: _feedHeader(context, inset),
                ),
                _feedSliver(context, inset),
                const LoftifyNavClearanceSliver(),
              ],
            ),
          );
        },
      ),
     ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, EdgeInsets padding) {
    return Padding(
      padding: padding,
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _continueSection(BuildContext context, double inset) {
    final design = context.design;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          context,
          appLocalizations.ao3ContinueReading,
          EdgeInsets.fromLTRB(inset, design.spacing.xl, inset, design.spacing.sm),
        ),
        SizedBox(
          height: 118,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: inset),
            scrollDirection: Axis.horizontal,
            itemCount: _continueReading.length,
            separatorBuilder: (context, index) =>
                SizedBox(width: design.spacing.md),
            itemBuilder: (context, index) {
              final entry = _continueReading[index];
              return SizedBox(
                width: 250,
                child: GestureDetector(
                  // Desktop discovery: right-click opens the same menu mobile
                  // reaches with a long press.
                  onSecondaryTap: () => _showShelfMenu(entry),
                  child: LoftifyCard(
                  variant: LoftifyCardVariant.outlined,
                  padding: EdgeInsets.all(design.spacing.lg),
                  onLongPress: () => _showShelfMenu(entry),
                  onTap: () => RouteUtil.pushPanelCupertinoRoute(
                    context,
                    Ao3ReaderScreen(workId: entry.id),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          entry.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      SizedBox(height: design.spacing.sm),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(design.radii.full),
                        child: LinearProgressIndicator(
                          value: entry.chapterCount > 0
                              ? (entry.chapterIndex / entry.chapterCount)
                                  .clamp(0.0, 1.0)
                              : 0.0,
                          minHeight: 4,
                          backgroundColor: design.colors.surfaceMuted,
                        ),
                      ),
                      SizedBox(height: design.spacing.xs),
                      Text(
                        appLocalizations.ao3ChapterCounter(
                            entry.chapterIndex.toString(),
                            entry.chapterCount.toString()),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: design.colors.textMuted),
                      ),
                    ],
                  ),
                ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Long press / right click on a shelf card: open it or drop it, without
  /// having to find the shelf screen first.
  void _showShelfMenu(Ao3LibraryEntry entry) {
    BottomSheetBuilder.showContextMenu(
      context,
      FlutterContextMenu(
        entries: [
          FlutterContextMenuItem(
            appLocalizations.ao3OpenLink,
            iconData: LoftifyIcons.book,
            onPressed: () => RouteUtil.pushPanelCupertinoRoute(
              context,
              Ao3ReaderScreen(workId: entry.id),
            ),
          ),
          FlutterContextMenuItem(
            appLocalizations.ao3RemoveWork,
            iconData: LoftifyIcons.delete,
            status: MenuItemStatus.error,
            onPressed: () {
              DialogBuilder.showConfirmDialog(
                context,
                title: appLocalizations.ao3RemoveWork,
                message: appLocalizations.ao3RemoveWorkMessage(
                  entry.title.isEmpty
                      ? appLocalizations.ao3Reader
                      : entry.title,
                ),
                confirmButtonText: appLocalizations.confirm,
                cancelButtonText: appLocalizations.cancel,
                onTapConfirm: () async {
                  await Ao3Store().remove(entry.id);
                  if (!mounted) return;
                  _loadLocal();
                  IToast.showTop(appLocalizations.ao3Removed);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tagRow(BuildContext context, double inset) {
    final design = context.design;
    return Padding(
      padding: EdgeInsets.fromLTRB(inset, design.spacing.lg, inset, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            context,
            appLocalizations.ao3FollowedTags,
            EdgeInsets.only(bottom: design.spacing.sm),
          ),
          Wrap(
            spacing: design.spacing.sm,
            runSpacing: design.spacing.sm,
            children: [
              LoftifyTag(
                label: appLocalizations.ao3AllTags,
                selected: _activeTag.isEmpty,
                onPressed: () => _activateTag(""),
              ),
              for (final tag in _followed)
                GestureDetector(
                  onLongPress: () => _confirmUnfollow(tag),
                  child: LoftifyTag(
                    label: tag,
                    maxWidth: 200,
                    selected: _activeTag == tag,
                    onPressed: () => _activateTag(tag),
                  ),
                ),
              LoftifyTag(
                label: appLocalizations.ao3AddTag,
                leading: LoftifyIcons.add,
                showSelectedIcon: false,
                onPressed: _openManageSheet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _feedHeader(BuildContext context, double inset) {
    final design = context.design;
    return Padding(
      padding: EdgeInsets.fromLTRB(inset, design.spacing.xl, inset, design.spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ...[
            LoftifyCard(
              variant: LoftifyCardVariant.muted,
              padding: EdgeInsets.symmetric(
                horizontal: design.spacing.lg,
                vertical: design.spacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () => RouteUtil.pushPanelCupertinoRoute(
                      context,
                      const Ao3SettingScreen(),
                    ),
                    child: Text(appLocalizations.setting),
                  ),
                  TextButton(
                    onPressed: _refresh,
                    child: Text(appLocalizations.ao3Retry),
                  ),
                ],
              ),
            ),
            SizedBox(height: design.spacing.md),
          ],
          Text(
            _activeTag.isEmpty
                ? appLocalizations.ao3LatestWorks
                : _activeTag,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _feedSliver(BuildContext context, double inset) {
    final feed = _visibleFeed;
    if (_followed.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: LoftifyStateView(
            visual: LoftifyStateVisual.empty,
            title: appLocalizations.ao3FeedEmpty,
            message: appLocalizations.ao3FeedEmptyHint,
          ),
        ),
      );
    }
    if (feed.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.design.spacing.xxl),
            child: Center(
              child: _refreshing
                  ? Text(appLocalizations.ao3Loading,
                      style: Theme.of(context).textTheme.bodySmall)
                  : Text(appLocalizations.ao3SearchEmpty,
                      style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      sliver: SliverList.separated(
        itemCount: feed.length,
        separatorBuilder: (context, index) =>
            SizedBox(height: context.design.spacing.sm),
        itemBuilder: (context, index) {
          final entry = feed[index];
          return Ao3WorkCard(
            entry: entry,
            onTap: () => RouteUtil.pushPanelCupertinoRoute(
              context,
              Ao3ReaderScreen(workId: entry.workId),
            ),
          );
        },
      ),
    );
  }
}
