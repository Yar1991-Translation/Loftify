import 'package:flutter/material.dart';

import '../../generated/app_localizations.dart';
import '../loftify_icons.dart';

/// Material 3 side navigation for the tablet shell.
///
/// The classic compact [NavigationRail]: a fixed 80dp column with each
/// destination's label under its icon (the M3 medium-class form used
/// across Google's tablet apps) and the standard M3 selection treatment —
/// a `secondaryContainer` indicator pill with `onSecondaryContainer`
/// glyphs. Actions passed via [trailing] pin to the rail's bottom through
/// the rail's own `trailingAtBottom`, where the spec places trailing
/// actions such as settings or account.
///
/// The rail paints its own `surfaceContainerLow` backdrop and the shell
/// adds no divider: M3 separates navigation and content tonally. The
/// rail must be given a bounded height (the tablet shell always does);
/// like Flutter's NavigationRail it cannot shrink-wrap one.
class LoftifyNavigationRail extends StatelessWidget {
  const LoftifyNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.trailing,
  });

  /// `null` clears the indicator while a sub-page covers the tab content
  /// (mirrors the desktop sidebar's deselection behaviour).
  final int? selectedIndex;

  final ValueChanged<int> onDestinationSelected;

  /// Actions pinned to the bottom of the rail (theme toggle, settings...).
  final List<Widget>? trailing;

  /// The M3 compact rail column width.
  static const double railWidth = 80;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final labels = [l10n.home, l10n.search, l10n.dynamicTab, l10n.mine];
    final icons = [
      LoftifyIcons.home,
      LoftifyIcons.search,
      LoftifyIcons.activity,
      LoftifyIcons.profile,
    ];
    return Material(
      color: colorScheme.surfaceContainerLow,
      child: SizedBox(
        width: railWidth,
        child: NavigationRail(
          selectedIndex: selectedIndex,
          labelType: NavigationRailLabelType.all,
          minWidth: railWidth,
          backgroundColor: colorScheme.surfaceContainerLow,
          indicatorColor: colorScheme.secondaryContainer,
          selectedIconTheme: IconThemeData(color: colorScheme.onSecondaryContainer),
          unselectedIconTheme:
              IconThemeData(color: colorScheme.onSurfaceVariant),
          trailingAtBottom: true,
          trailing: trailing == null || trailing!.isEmpty
              ? null
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [...trailing!, const SizedBox(height: 16)],
                ),
          onDestinationSelected: onDestinationSelected,
          destinations: [
            for (var i = 0; i < labels.length; i++)
              NavigationRailDestination(
                icon: Icon(icons[i]),
                selectedIcon: Icon(icons[i]),
                label: Text(labels[i]),
              ),
          ],
        ),
      ),
    );
  }
}
