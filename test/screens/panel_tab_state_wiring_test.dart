import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The floating bar collapses by listening to the active tab's scroll
/// controllers, which the shell finds through that tab's key. Indexing the
/// key map directly only reaches the tabs that create their own key, so the
/// home and search tabs reported no controllers and the bar silently stopped
/// collapsing there. These assertions pin the single lookup path.
void main() {
  final source = File('lib/Screens/panel_screen.dart').readAsStringSync();

  test('tab state lookup goes through the key resolver', () {
    expect(source, contains('_keyFor(choice)'));
    expect(source, contains('State? _stateOf(SideBarChoice choice)'));
    expect(
      source,
      isNot(contains('_keys[Ao3Nav.choiceAt')),
      reason: 'indexing the key map directly misses the home and search tabs',
    );
  });

  test('the bar reads controllers through the shared helper', () {
    expect(
      source,
      contains('_scrollControllersOf(Ao3Nav.choiceAt(_currentIndex))'),
    );
    expect(
      source,
      contains('_bottomNavigationOf(Ao3Nav.choiceAt(index))'),
    );
  });

  test('every root tab can hand out its scroll controllers', () {
    for (final file in [
      'lib/Screens/Navigation/home_screen.dart',
      'lib/Screens/Navigation/search_screen.dart',
      'lib/Screens/Navigation/dynamic_screen.dart',
      'lib/Screens/Navigation/mine_screen.dart',
      'lib/Screens/AO3/ao3_home_screen.dart',
    ]) {
      expect(
        File(file).readAsStringSync(),
        contains('List<ScrollController> getScrollControllers()'),
        reason: '$file must expose its scroll controllers to the shell',
      );
    }
  });
}
