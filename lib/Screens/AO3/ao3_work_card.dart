import 'package:flutter/material.dart';

import '../../Models/ao3_feed_entry.dart';
import '../../Theme/loftify_design_theme.dart';
import '../../Widgets/Design/loftify_surfaces.dart';
import '../../l10n/l10n.dart';

/// A listing row for the home feed and the search results: the least a
/// reader needs to decide whether to open a work.
class Ao3WorkCard extends StatelessWidget {
  const Ao3WorkCard({
    super.key,
    required this.entry,
    this.onTap,
  });

  final Ao3FeedEntry entry;
  final VoidCallback? onTap;

  String _updated() {
    final date = DateTime.fromMillisecondsSinceEpoch(entry.updatedAtMs);
    final now = DateTime.now();
    final difference = now.difference(date);
    String two(int value) => value.toString().padLeft(2, '0');
    if (difference.inDays >= 0 && difference.inDays < 1) {
      return appLocalizations.ao3Published('${two(date.hour)}:${two(date.minute)}');
    }
    if (difference.inDays >= 1 && difference.inDays < 30) {
      return appLocalizations.ao3FeedDaysAgo('${difference.inDays}');
    }
    final monthDay = '${two(date.month)}-${two(date.day)}';
    return date.year == now.year ? monthDay : '${date.year}-${monthDay}';
  }

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final colors = design.colors;
    final theme = Theme.of(context);
    final meta = <String>[
      if (entry.rating.isNotEmpty) entry.rating,
      if (entry.words != null)
        appLocalizations.ao3WordCount(entry.words.toString()),
      if (entry.chapters.isNotEmpty) entry.chapters,
    ];
    return LoftifyCard(
      variant: LoftifyCardVariant.outlined,
      padding: EdgeInsets.all(design.spacing.lg),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
          SizedBox(height: design.spacing.xs),
          Text(
            <String>[
              if (entry.author.isNotEmpty) entry.author,
              if (entry.updatedAtMs > 0) _updated(),
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          if (entry.summaryText.isNotEmpty) ...[
            SizedBox(height: design.spacing.sm),
            Text(
              entry.summaryText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colors.textSecondary),
            ),
          ],
          if (meta.isNotEmpty || entry.tags.isNotEmpty) ...[
            SizedBox(height: design.spacing.sm),
            Text(
              <String>[...meta, ...entry.tags.take(3)].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: colors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}