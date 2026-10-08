import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Api/ao3_api.dart';
import '../../Api/ao3_feed_api.dart';
import '../../Models/ao3_feed_entry.dart';
import '../../Theme/loftify_design_theme.dart';
import '../../Widgets/Design/loftify_controls.dart';
import '../../Widgets/Design/loftify_state_view.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';
import 'ao3_reader_screen.dart';
import 'ao3_work_card.dart';

enum Ao3SearchMode { byText, byTag }

/// AO3 search. The text mode goes through the site search, which is slow
/// (tens of seconds); the tag mode reads a tag listing instead and is fast,
/// so the mode is a first-class choice rather than a hidden fallback.
class Ao3SearchScreen extends StatefulWidget {
  const Ao3SearchScreen({
    super.key,
    this.initialQuery = '',
    this.initialMode = Ao3SearchMode.byText,
  });

  final String initialQuery;
  final Ao3SearchMode initialMode;

  @override
  State<Ao3SearchScreen> createState() => Ao3SearchScreenState();
}

class Ao3SearchScreenState extends BaseDynamicState<Ao3SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final EasyRefreshController _refreshController = EasyRefreshController();
  Ao3SearchMode _mode = Ao3SearchMode.byText;
  List<Ao3FeedEntry> _results = const [];
  int _page = 1;
  bool _hasMore = false;
  bool _loading = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery.trim();
    _controller.text = _query;
    _mode = widget.initialMode;
    if (_query.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _search(reset: true);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _search({bool reset = true, bool loadMore = false}) async {
    if (_loading) return;
    final query = _query;
    if (query.isEmpty) return;
    final page = loadMore ? _page + 1 : 1;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _page = 1;
        _results = const [];
        _hasMore = false;
      }
    });
    try {
      final entries = _mode == Ao3SearchMode.byTag
          ? await Ao3FeedApi.fetchTagWorks(query, page: page)
          : await Ao3FeedApi.searchWorks(query, page: page);
      if (!mounted) return;
      setState(() {
        _page = page;
        _results = loadMore ? [..._results, ...entries] : entries;
        _hasMore = entries.length >= Ao3FeedApi.pageSize;
      });
    } on Ao3Exception catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFor(error));
    } catch (error, stack) {
      ILogger.error("AO3 search failed", error, stack);
      if (mounted) setState(() => _error = appLocalizations.loadFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _messageFor(Ao3Exception error) {
    switch (error.failure) {
      case Ao3Failure.notFound:
        return _mode == Ao3SearchMode.byTag
            ? appLocalizations.ao3TagNotFound
            : appLocalizations.ao3SearchEmpty;
      case Ao3Failure.blocked:
        return appLocalizations.ao3Blocked;
      case Ao3Failure.disabled:
        return appLocalizations.ao3Disabled;
      case Ao3Failure.timeout:
      case Ao3Failure.network:
      case Ao3Failure.loginRequired:
      case Ao3Failure.notAWork:
        return appLocalizations.ao3NetworkFailed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    return Scaffold(
      backgroundColor: design.colors.page,
      appBar: ResponsiveAppBar(
        showBack: true,
        title: appLocalizations.ao3SearchWorks,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(design.spacing.lg),
            child: ItemBuilder.buildSearchBar(
              context: context,
              hintText: appLocalizations.ao3SearchWorksHint,
              controller: _controller,
              onSubmitted: (value) {
                _query = value?.toString().trim() ?? '';
                if (_query.isEmpty) return;
                _search(reset: true);
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: design.spacing.lg),
            child: Row(
              children: [
                LoftifyTag(
                  label: appLocalizations.ao3SearchByText,
                  leading: LoftifyIcons.search,
                  showSelectedIcon: false,
                  selected: _mode == Ao3SearchMode.byText,
                  onPressed: () {
                    if (_mode == Ao3SearchMode.byText) return;
                    setState(() => _mode = Ao3SearchMode.byText);
                  },
                ),
                SizedBox(width: design.spacing.sm),
                LoftifyTag(
                  label: appLocalizations.ao3SearchByTag,
                  leading: LoftifyIcons.bookmark,
                  showSelectedIcon: false,
                  selected: _mode == Ao3SearchMode.byTag,
                  onPressed: () {
                    if (_mode == Ao3SearchMode.byTag) return;
                    setState(() => _mode = Ao3SearchMode.byTag);
                  },
                ),
              ],
            ),
          ),
          if (_mode == Ao3SearchMode.byText)
            Padding(
              padding: EdgeInsets.fromLTRB(
                design.spacing.lg,
                design.spacing.sm,
                design.spacing.lg,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  appLocalizations.ao3SearchSlowHint,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: design.colors.textMuted),
                ),
              ),
            ),
          Expanded(
            child: _buildBody(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final design = context.design;
    if (_query.isEmpty) {
      return LoftifyStateView(
        visual: LoftifyStateVisual.empty,
        title: appLocalizations.ao3SearchWorksHint,
      );
    }
    if (_error != null && _results.isEmpty) {
      return LoftifyStateView(
        visual: LoftifyStateVisual.error,
        title: _error!,
        actionLabel: appLocalizations.ao3Retry,
        onAction: () => _search(reset: true),
      );
    }
    if (_loading && _results.isEmpty) {
      return LoftifyStateView(
        visual: LoftifyStateVisual.loading,
        title: _mode == Ao3SearchMode.byText
            ? appLocalizations.ao3SearchSlowHint
            : appLocalizations.ao3Loading,
      );
    }
    return EasyRefresh(
      controller: _refreshController,
      onLoad: _hasMore && !_loading ? () => _search(reset: false, loadMore: true) : null,
      child: _results.isEmpty
          ? ListView(
              children: [
                Padding(
                  padding: EdgeInsets.all(design.spacing.xxl),
                  child: Center(
                    child: Text(
                      appLocalizations.ao3SearchEmpty,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            )
          : ListView.separated(
              controller: _scrollController,
              padding: EdgeInsets.all(design.spacing.lg),
              itemCount: _results.length + 1,
              separatorBuilder: (context, index) =>
                  SizedBox(height: design.spacing.sm),
              itemBuilder: (context, index) {
                if (index == _results.length) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: design.spacing.lg),
                    child: Center(
                      child: Text(
                        _hasMore
                            ? appLocalizations.ao3Loading
                            : appLocalizations.ao3FeedEnd,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  );
                }
                final entry = _results[index];
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