import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Screens/AO3/ao3_reader_screen.dart';
import '../../Screens/AO3/ao3_theme.dart';
import '../../Theme/loftify_design_theme.dart';
import '../../Utils/ao3_store.dart';
import '../../Utils/uri_util.dart';
import '../../Widgets/Design/loftify_reading.dart';
import '../../Widgets/Design/loftify_state_view.dart';
import '../../Widgets/Design/loftify_surfaces.dart';
import '../../Widgets/Navigation/loftify_glass_navigation_bar.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';

/// Offline shelf: every AO3 work the reader has opened, newest first.
class Ao3LibraryScreen extends StatefulWidget {
  const Ao3LibraryScreen({super.key});

  static const String routeName = "/ao3/library";

  @override
  State<Ao3LibraryScreen> createState() => _Ao3LibraryScreenState();
}

class _Ao3LibraryScreenState extends BaseDynamicState<Ao3LibraryScreen> {
  final Ao3Store _store = Ao3Store();
  List<Ao3LibraryEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() => _entries = _store.entries());
  }

  Future<void> _openWork(int id) {
    return RouteUtil.pushPanelCupertinoRoute(
        context, Ao3ReaderScreen(workId: id));
  }

  void _pasteLink() {
    BottomSheetBuilder.showBottomSheet(
      context,
      (sheetContext) => InputBottomSheet(
        title: appLocalizations.ao3PasteLink,
        buttonText: appLocalizations.ao3OpenLink,
        text: '',
        onConfirm: (text) {
          final workId = LoftifyUriUtil.extractAo3WorkId(text);
          if (workId == null) {
            IToast.showTop(appLocalizations.ao3InvalidLink);
            return;
          }
          _openWork(workId);
        },
      ),
      preferMinWidth: 400,
      responsive: true,
    );
  }

  void _confirmRemove(Ao3LibraryEntry entry) {
    DialogBuilder.showConfirmDialog(
      context,
      title: appLocalizations.ao3RemoveWork,
      message: appLocalizations.ao3RemoveWorkMessage(entry.title),
      confirmButtonText: appLocalizations.confirm,
      cancelButtonText: appLocalizations.cancel,
      onTapConfirm: () async {
        await _store.remove(entry.id);
        if (!mounted) return;
        _reload();
        IToast.showTop(appLocalizations.ao3Removed);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Ao3Theme(
      child: Scaffold(
      backgroundColor: ChewieTheme.getBackground(context),
      appBar: ResponsiveAppBar(
        showBack: true,
        title: appLocalizations.ao3Library,
        actions: [
          ChewieIconButton(
            icon: LoftifyIcons.add,
            tooltip: appLocalizations.ao3PasteLink,
            onPressed: _pasteLink,
          ),
        ],
      ),
      body: _entries.isEmpty ? _buildEmpty() : _buildList(),
      ),
    );
  }

  Widget _buildEmpty() {
    return LoftifyStateView(
      visual: LoftifyStateVisual.empty,
      title: appLocalizations.ao3EmptyLibrary,
      message: appLocalizations.ao3EmptyLibraryHint,
      actionLabel: appLocalizations.ao3PasteLink,
      onAction: _pasteLink,
    );
  }

  Widget _buildList() {
    final design = context.design;
    final colors = design.colors;
    final theme = Theme.of(context);
    return LoftifyReadingFrame(
      maximumContentWidth: design.grid.maximumContentWidth,
      topPadding: design.spacing.md,
      bottomPadding: LoftifyGlassNavigationBar.contentBottomPadding(context),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: _entries.length,
        separatorBuilder: (context, index) =>
            SizedBox(height: design.spacing.sm),
        itemBuilder: (context, index) {
          final entry = _entries[index];
          final subtitle = <String>[
            if (entry.author.isNotEmpty)
              appLocalizations.ao3ByAuthor(entry.author),
            appLocalizations.ao3ChapterCounter(
                entry.chapterIndex.toString(), entry.chapterCount.toString()),
            entry.cached
                ? appLocalizations.ao3Cached
                : appLocalizations.ao3OnlineOnly,
          ].join(' · ');
          // A chapter counter alone hides how far in the reader is, so started
          // works carry a thin M3 progress indicator. Never-opened works would
          // only show an empty track, so they stay clean.
          final started = entry.chapterIndex > 1 ||
              entry.lastReadAtMs > entry.savedAtMs;
          final showProgress = entry.chapterCount > 1 && started;
          final progress = showProgress
              ? (entry.chapterIndex / entry.chapterCount).clamp(0.0, 1.0)
              : 0.0;
          // Swipe left to remove: the delete affordance has to be a gesture
          // people try, not a small icon they have to hunt for.
          return Dismissible(
            key: ValueKey('ao3-shelf-' + entry.id.toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: design.spacing.xxl),
              decoration: BoxDecoration(
                color: colors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(design.radii.card),
              ),
              child: Icon(
                LoftifyIcons.delete,
                color: colors.danger,
              ),
            ),
            confirmDismiss: (_) {
              _confirmRemove(entry);
              return Future.value(false);
            },
            child: GestureDetector(
            onSecondaryTap: () => _showCardMenu(entry),
            child: LoftifyCard(
            variant: LoftifyCardVariant.outlined,
            padding: EdgeInsets.all(design.spacing.lg),
            onLongPress: () => _showCardMenu(entry),
            onTap: () async {
              await _openWork(entry.id);
              _reload();
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title.isEmpty
                            ? appLocalizations.ao3Reader
                            : entry.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      SizedBox(height: design.spacing.xs),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colors.textMuted),
                      ),
                      if (showProgress) ...[
                        SizedBox(height: design.spacing.md),
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(design.radii.full),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: colors.surfaceMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: design.spacing.sm),
                ChewieIconButton(
                  icon: LoftifyIcons.delete,
                  tooltip: appLocalizations.delete,
                  onPressed: () => _confirmRemove(entry),
                ),
              ],
            ),
            ),
          ),
        );
      },
    ),
    );
  }

  /// Right click / long press on a card: the same two actions as the icon and
  /// the swipe, in the shape desktop users reach for.
  void _showCardMenu(Ao3LibraryEntry entry) {
    BottomSheetBuilder.showContextMenu(
      context,
      FlutterContextMenu(
        entries: [
          FlutterContextMenuItem(
            appLocalizations.ao3OpenLink,
            iconData: LoftifyIcons.book,
            onPressed: () async {
              await _openWork(entry.id);
              _reload();
            },
          ),
          FlutterContextMenuItem(
            appLocalizations.ao3RemoveWork,
            iconData: LoftifyIcons.delete,
            status: MenuItemStatus.error,
            onPressed: () => _confirmRemove(entry),
          ),
        ],
      ),
    );
  }
}
