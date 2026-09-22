import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Source-contract tests for the three-way shell split in MainScreen:
/// desktop keeps its windowed sidebar, tablets get the Material
/// NavigationRail shell, phones keep the floating bottom bar.
void main() {
  final mainScreen = File(
    'lib/Screens/main_screen.dart',
  ).readAsStringSync();
  final panelScreen = File(
    'lib/Screens/panel_screen.dart',
  ).readAsStringSync();
  final responsiveUtil = File(
    'third-party/chewie/lib/src/Utils/General/responsive_util.dart',
  ).readAsStringSync();

  test('main screen routes tablets to the NavigationRail shell', () {
    expect(mainScreen, contains('ResponsiveUtil.isTabletLayout()'));
    expect(mainScreen, contains('LoftifyNavigationRail('));
    expect(mainScreen, isNot(contains('selectByResponsive')));
  });

  test('tablet shell carries no desktop window chrome', () {
    final tabletBody = mainScreen.split('_buildTabletBody()')[1].split(
      '_buildNavigationRail',
    )[0];
    expect(tabletBody, isNot(contains('WindowMoveHandle')));
    expect(tabletBody, isNot(contains('_titleBar')));
    expect(tabletBody, isNot(contains('WindowTitleWrapper')));
  });

  test('glass bottom bar is phone-only', () {
    expect(panelScreen, contains('ResponsiveUtil.isTabletLayout()'));
    // The bar must not mount when the rail or the desktop sidebar is shown.
    expect(
      panelScreen,
      contains('ResponsiveUtil.isLandscapeLayout() ||'),
    );
  });

  test('landscape desktop-layout toggle is fully removed', () {
    expect(responsiveUtil, isNot(contains('enableLandscapeInTablet')));
    expect(responsiveUtil, contains('static bool isTabletLayout()'));
    // isLandscapeLayout means desktop/web only — tablets never qualify.
    final body = responsiveUtil.split('static bool isLandscapeLayout')[1].split(
      'static bool isTabletLayout',
    )[0];
    expect(body, isNot(contains('isLandscapeTablet')));
  });
}
