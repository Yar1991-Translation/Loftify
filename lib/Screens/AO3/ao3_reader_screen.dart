import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Api/ao3_api.dart';
import '../../Models/ao3_work.dart';
import '../../Theme/loftify_design_theme.dart';
import '../../Utils/ao3_config.dart';
import '../../Utils/ao3_store.dart';
import '../../Widgets/Design/loftify_state_view.dart';
import '../../Widgets/Navigation/loftify_glass_navigation_bar.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';

enum _ReaderPhase { loading, ready, failed }

/// Native reader for an AO3 work: the export is fetched once, cached in the
/// `ao3` box and rendered with the same HTML widget the post reader uses.
class Ao3ReaderScreen extends StatefulWidget {
  const Ao3ReaderScreen({
    super.key,
    required this.workId,
    this.startChapter,
    this.store,
  });

  final int workId;
  final int? startChapter;

  /// Injected by tests; production always uses the shared `ao3` box.
  final Ao3Store? store;

  @override
  State<Ao3ReaderScreen> createState() => _Ao3ReaderScreenState();
}

class _Ao3ReaderScreenState extends BaseDynamicState<Ao3ReaderScreen> {
  late final Ao3Store _store = widget.store ?? Ao3Store();
  final ScrollController _scrollController = ScrollController();

  _ReaderPhase _phase = _ReaderPhase.loading;
  Ao3Work? _work;
  Ao3Exception? _error;
  int _chapterIndex = 1;
  bool _fromCache = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool force = false}) async {
    if (!force) {
      final cached = _store.read(widget.workId);
      if (cached != null) {
        _apply(cached, fromCache: true);
        return;
      }
    }
    setState(() {
      _phase = _ReaderPhase.loading;
      _error = null;
    });
    try {
      final work = await Ao3Api.fetchWork(widget.workId);
      await _store.save(work);
      if (!mounted) return;
      _apply(work, fromCache: false);
    } on Ao3Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _phase = _ReaderPhase.failed;
        _error = error;
      });
    } catch (error, stackTrace) {
      ILogger.error('Failed to load AO3 work', error, stackTrace);
      if (!mounted) return;
      setState(() {
        _phase = _ReaderPhase.failed;
        _error = const Ao3Exception(Ao3Failure.network);
      });
    }
  }

  void _apply(Ao3Work work, {required bool fromCache}) {
    final stored = _store.entry(work.id)?.chapterIndex;
    var index = widget.startChapter ?? stored ?? 1;
    if (index < 1 || index > work.chapters.length) index = 1;
    setState(() {
      _work = work;
      _chapterIndex = index;
      _phase = _ReaderPhase.ready;
      _fromCache = fromCache;
    });
    _store.updateProgress(work.id, index);
  }

  void _goToChapter(int index) {
    final work = _work;
    if (work == null || index < 1 || index > work.chapters.length) return;
    setState(() => _chapterIndex = index);
    _store.updateProgress(work.id, index);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _openOnSite() {
    final work = _work;
    final url = work?.sourceUrl ??
        'https://archiveofourown.org/works/' + widget.workId.toString();
    RouteUtil.pushPanelCupertinoRoute(
      context,
      WebviewScreen(url: url, processUri: false),
    );
  }

  /// The AO3 export has no comment page, so the shelf keeps only the work.
  void _showChapterList(Ao3Work work) {
    BottomSheetBuilder.showBottomSheet(
      context,
      (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.design.spacing.xl,
                vertical: context.design.spacing.md,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  appLocalizations.ao3ChapterList,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: work.chapters.length,
                itemBuilder: (itemContext, index) {
                  final chapter = work.chapters[index];
                  return ListTile(
                    title: Text(
                      chapter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(appLocalizations.ao3ChapterCounter(
                        chapter.index.toString(),
                        work.chapters.length.toString())),
                    selected: chapter.index == _chapterIndex,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _goToChapter(chapter.index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      preferMinWidth: 400,
      responsive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final work = _work;
    return Scaffold(
      backgroundColor: ChewieTheme.getBackground(context),
      appBar: ResponsiveAppBar(
        showBack: true,
        title: work?.title ?? appLocalizations.ao3Reader,
        actions: [
          if (work != null && work.isMultiChapter)
            ChewieIconButton(
              icon: LoftifyIcons.listLayout,
              tooltip: appLocalizations.ao3ChapterList,
              onPressed: () => _showChapterList(work),
            ),
          ChewieIconButton(
            icon: LoftifyIcons.openExternal,
            tooltip: appLocalizations.ao3OpenOnSite,
            onPressed: _openOnSite,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _ReaderPhase.loading:
        return LoftifyStateView(
          visual: LoftifyStateVisual.loading,
          title: appLocalizations.ao3Loading,
        );
      case _ReaderPhase.failed:
        return LoftifyStateView(
          visual: LoftifyStateVisual.error,
          title: _errorTitle(_error),
          message: _errorMessage(_error),
          actionLabel: appLocalizations.ao3Retry,
          onAction: () => _load(force: true),
        );
      case _ReaderPhase.ready:
        return _buildReader(_work!);
    }
  }

  Widget _buildReader(Ao3Work work) {
    final chapter = work.chapters[_chapterIndex - 1];
    final design = context.design;
    final fontSizeFactor = Ao3Config.load().fontScale;
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(child: _buildWorkHeader(work)),
        if (work.isMultiChapter)
          SliverToBoxAdapter(child: _buildChapterBar(work)),
        if (chapter.notesHtml.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildNoteBlock(
              appLocalizations.ao3ChapterNotes,
              chapter.notesHtml,
              fontSizeFactor,
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: design.spacing.xl),
            child: CustomHtmlWidget(
              content: chapter.bodyHtml,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.apply(fontSizeFactor: fontSizeFactor, heightFactor: 1.2),
            ),
          ),
        ),
        if (chapter.endNotesHtml.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildNoteBlock(
              appLocalizations.ao3ChapterEndNotes,
              chapter.endNotesHtml,
              fontSizeFactor,
            ),
          ),
        if (work.isMultiChapter)
          SliverToBoxAdapter(child: _buildChapterBar(work)),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        const LoftifyNavClearanceSliver(),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildWorkHeader(Ao3Work work) {
    final design = context.design;
    final colors = design.colors;
    final theme = Theme.of(context);
    final stats = <String>[
      if (work.author.isNotEmpty) appLocalizations.ao3ByAuthor(work.author),
      if (work.words != null)
        appLocalizations.ao3WordCount(work.words.toString()),
      if (work.chaptersStat.isNotEmpty)
        appLocalizations.ao3ChapterCounter(
            _chapterIndex.toString(), work.chapters.length.toString()),
      if (work.publishedAt.isNotEmpty)
        appLocalizations.ao3Published(work.publishedAt),
      if (_fromCache) appLocalizations.ao3Cached,
    ];
    final chips = <Widget>[
      for (final group in work.tagGroups)
        for (final value in group.values)
          Container(
            margin: EdgeInsets.only(
                right: design.spacing.sm, bottom: design.spacing.sm),
            padding: EdgeInsets.symmetric(
                horizontal: design.spacing.md, vertical: design.spacing.xs),
            decoration: BoxDecoration(
              color: colors.surfaceMuted,
              borderRadius: BorderRadius.circular(design.radii.full),
              border: Border.all(color: colors.outline),
            ),
            child: Text(
              value,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        design.spacing.xl,
        design.spacing.xl,
        design.spacing.xl,
        design.spacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            work.title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: design.spacing.sm),
          Text(
            stats.join(' · '),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colors.textMuted),
          ),
          if (chips.isNotEmpty) ...[
            SizedBox(height: design.spacing.lg),
            Wrap(children: chips),
          ],
          if (work.summaryHtml.isNotEmpty) ...[
            SizedBox(height: design.spacing.md),
            CustomHtmlWidget(
              content: work.summaryHtml,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colors.textSecondary),
            ),
          ],
          if (work.notesHtml.isNotEmpty) ...[
            SizedBox(height: design.spacing.md),
            CustomHtmlWidget(
              content: work.notesHtml,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colors.textMuted),
            ),
          ],
          SizedBox(height: design.spacing.lg),
          Divider(color: colors.outline, height: 1),
        ],
      ),
    );
  }

  Widget _buildChapterBar(Ao3Work work) {
    final design = context.design;
    final hasPrevious = _chapterIndex > 1;
    final hasNext = _chapterIndex < work.chapters.length;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: design.spacing.md,
        vertical: design.spacing.sm,
      ),
      child: Row(
        children: [
          ChewieIconButton(
            icon: LoftifyIcons.previous,
            tooltip: appLocalizations.ao3PreviousChapter,
            onPressed: hasPrevious ? () => _goToChapter(_chapterIndex - 1) : null,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (work.chapters[_chapterIndex - 1].title.isNotEmpty)
                  Text(
                    work.chapters[_chapterIndex - 1].title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                Text(
                  appLocalizations.ao3ChapterCounter(
                      _chapterIndex.toString(), work.chapters.length.toString()),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          ChewieIconButton(
            icon: LoftifyIcons.next,
            tooltip: appLocalizations.ao3NextChapter,
            onPressed: hasNext ? () => _goToChapter(_chapterIndex + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildNoteBlock(String label, String html, double fontSizeFactor) {
    final design = context.design;
    final colors = design.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        design.spacing.xl,
        design.spacing.md,
        design.spacing.xl,
        design.spacing.md,
      ),
      child: Container(
        padding: EdgeInsets.all(design.spacing.lg),
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: BorderRadius.circular(design.radii.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: colors.textMuted),
            ),
            SizedBox(height: design.spacing.sm),
            CustomHtmlWidget(
              content: html,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.apply(fontSizeFactor: fontSizeFactor),
            ),
          ],
        ),
      ),
    );
  }

  String _errorTitle(Ao3Exception? error) {
    switch (error?.failure) {
      case Ao3Failure.blocked:
        return appLocalizations.ao3Blocked;
      case Ao3Failure.notFound:
        return appLocalizations.ao3NotFound;
      case Ao3Failure.loginRequired:
        return appLocalizations.ao3LoginRequired;
      case Ao3Failure.notAWork:
        return appLocalizations.ao3NotAWork;
      case Ao3Failure.disabled:
        return appLocalizations.ao3Disabled;
      case Ao3Failure.timeout:
      case Ao3Failure.network:
      case null:
        return appLocalizations.ao3NetworkFailed;
    }
  }

  String _errorMessage(Ao3Exception? error) {
    switch (error?.failure) {
      case Ao3Failure.loginRequired:
        return appLocalizations.ao3LoginRequiredHint;
      case Ao3Failure.blocked:
        return appLocalizations.ao3BlockedHint;
      case Ao3Failure.disabled:
        return appLocalizations.ao3DisabledHint;
      case Ao3Failure.notFound:
      case Ao3Failure.notAWork:
        return appLocalizations.ao3NotFoundHint;
      case Ao3Failure.timeout:
      case Ao3Failure.network:
      case null:
        return appLocalizations.ao3NetworkHint;
    }
  }
}
