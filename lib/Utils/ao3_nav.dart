import 'package:flutter/material.dart';

import 'ao3_config.dart';
import 'enums.dart';
import '../Widgets/loftify_icons.dart';

/// The single source of truth for which root tabs exist. The AO3 tab is part
/// of the shell only while AO3 reading is enabled in settings, and every
/// navigation surface (phone glass bar, tablet rail, desktop sidebar) derives
/// its order from [choices] so the indices can never drift apart.
abstract final class Ao3Nav {
  static bool get enabled => Ao3Config.load().enabled;

  static List<SideBarChoice> choices() => [
        SideBarChoice.Home,
        SideBarChoice.Search,
        if (enabled) SideBarChoice.Ao3,
        SideBarChoice.Dynamic,
        SideBarChoice.Mine,
      ];

  /// The tab at a navigation bar position, which never includes hidden tabs.
  static SideBarChoice choiceAt(int visibleIndex) {
    final visible = choices();
    if (visibleIndex < 0 || visibleIndex >= visible.length) {
      return SideBarChoice.Home;
    }
    return visible[visibleIndex];
  }

  /// The navigation bar position of a tab, or 0 when it is hidden.
  static int visibleIndex(SideBarChoice choice) {
    final index = choices().indexOf(choice);
    return index < 0 ? 0 : index;
  }

  static IconData iconFor(SideBarChoice choice) => switch (choice) {
        SideBarChoice.Home => LoftifyIcons.home,
        SideBarChoice.Search => LoftifyIcons.search,
        SideBarChoice.Ao3 => LoftifyIcons.book,
        SideBarChoice.Dynamic => LoftifyIcons.activity,
        SideBarChoice.Mine => LoftifyIcons.profile,
      };
}
