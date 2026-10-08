import 'package:flutter/material.dart';

import '../../Utils/ao3_nav.dart';
import '../../Utils/enums.dart';
import '../../generated/app_localizations.dart';

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
    required this.choices,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.trailing,
  });

  /// The visible tabs, in order — derived from [Ao3Nav.choices] by the shell
  /// so every navigation surface agrees on the same list.
  final List<SideBarChoice> choices;

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
    String label(SideBarChoice choice) => switch (choice) {
          SideBarChoice.Home => l10n.home,
          SideBarChoice.Search => l10n.search,
          SideBarChoice.Ao3 => l10n.ao3Home,
          SideBarChoice.Dynamic => l10n.dynamicTab,
          SideBarChoice.Mine => l10n.mine,
        };
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
            for (final choice in choices)
              NavigationRailDestination(
                icon: Icon(Ao3Nav.iconFor(choice)),
                selectedIcon: Icon(Ao3Nav.iconFor(choice)),
                label: Text(label(choice)),
              ),
          ],
        ),
      ),
    );
  }
}
