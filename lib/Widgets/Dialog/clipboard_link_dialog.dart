import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Theme/loftify_design_theme.dart';
import '../../Utils/clipboard_link_controller.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';

/// Content only: the shared confirmation dialog owns its surface and route.
class ClipboardLinkDialog extends StatelessWidget {
  const ClipboardLinkDialog({super.key, required this.url, this.isAo3 = false});

  final String url;

  /// AO3 links open in the native reader, so they get their own wording.
  final bool isAo3;

  static Future<ClipboardLinkDecision?> show(
    BuildContext context,
    String url, {
    bool isAo3 = false,
  }) async {
    ClipboardLinkDecision? decision;
    await DialogBuilder.showConfirmDialog(
      context,
      messageChild: ClipboardLinkDialog(url: url, isAo3: isAo3),
      confirmButtonText: isAo3
          ? appLocalizations.ao3OpenLink
          : appLocalizations.clipboardLinkOpen,
      cancelButtonText: appLocalizations.clipboardLinkDismiss,
      onTapConfirm: () => decision = ClipboardLinkDecision.open,
      onTapCancel: () => decision = ClipboardLinkDecision.dismiss,
    );
    return decision;
  }

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final colors = design.colors;
    final uri = Uri.tryParse(url);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(design.spacing.lg),
              decoration: BoxDecoration(
                color: colors.accentContainer,
                borderRadius: BorderRadius.circular(design.radii.card),
              ),
              child: ChewieIcon(
                isAo3 ? LoftifyIcons.book : LoftifyIcons.link,
                size: 22,
                color: colors.onAccentContainer,
              ),
            ),
            SizedBox(width: design.spacing.lg),
            Expanded(
              child: Text(
                  isAo3
                      ? appLocalizations.ao3ClipboardTitle
                      : appLocalizations.clipboardLinkTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        SizedBox(height: design.spacing.xl),
        Text(
            isAo3
                ? appLocalizations.ao3ClipboardMessage
                : appLocalizations.clipboardLinkMessage,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colors.textSecondary, height: 1.5)),
        SizedBox(height: design.spacing.xl),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(design.spacing.lg),
          decoration: BoxDecoration(
            color: colors.surfaceMuted,
            borderRadius: BorderRadius.circular(design.radii.card),
            border: Border.all(color: colors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ChewieIcon(
                    LoftifyIcons.language,
                    size: 15,
                    color: colors.textMuted,
                  ),
                  SizedBox(width: design.spacing.md),
                  Expanded(
                      child: Text(uri?.host ?? 'LOFTER',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium)),
                ],
              ),
              SizedBox(height: design.spacing.sm),
              Text(url,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colors.textMuted, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
