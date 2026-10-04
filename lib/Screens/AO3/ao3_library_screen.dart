import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Screens/AO3/ao3_reader_screen.dart';
import '../../Theme/loftify_design_theme.dart';
import '../../Utils/ao3_store.dart';
import '../../Utils/uri_util.dart';
import '../../Widgets/Design/loftify_state_view.dart';
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

  void _openWork(int id) {
    RouteUtil.pushPanelCupertinoRoute(context, Ao3ReaderScreen(workId: id));
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
    return Scaffold(
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
    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: design.spacing.md),
      itemCount: _entries.length,
      separatorBuilder: (context, index) => Divider(
        color: colors.outline,
        height: 1,
        indent: design.spacing.xl,
        endIndent: design.spacing.xl,
      ),
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final subtitle = <String>[
          if (entry.author.isNotEmpty) appLocalizations.ao3ByAuthor(entry.author),
          appLocalizations.ao3ChapterCounter(
              entry.chapterIndex.toString(), entry.chapterCount.toString()),
          entry.cached ? appLocalizations.ao3Cached : appLocalizations.ao3OnlineOnly,
        ].join(' · ');
        return ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: design.spacing.xl),
          title: Text(
            entry.title.isEmpty
                ? appLocalizations.ao3Reader
                : entry.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          trailing: ChewieIconButton(
            icon: LoftifyIcons.delete,
            tooltip: appLocalizations.delete,
            onPressed: () => _confirmRemove(entry),
          ),
          onTap: () => _openWork(entry.id),
        );
      },
    );
  }
}
