import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Widgets/Design/loftify_scroll_to_top_button.dart';

void main() {
  setUpAll(() async {
    final hiveDirectory = Directory(
      '${Directory.current.path}/build/test_hive/scroll_to_top_button',
    );
    await hiveDirectory.create(recursive: true);
    Hive.init(hiveDirectory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  Widget host(ScrollController controller) {
    return MaterialApp(
      theme: LoftifyTheme.build(
        ChewieThemeColorData.defaultLightThemes.first,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Stack(
            children: [
              ListView(
                controller: controller,
                children: [
                  for (var i = 0; i < 40; i++)
                    SizedBox(height: 100, child: Text('Row $i')),
                ],
              ),
              LoftifyScrollToTopButton.hosted(
                context: context,
                scrollController: controller,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool visible(WidgetTester tester) => !tester
      .widget<IgnorePointer>(
        find
            .descendant(
              of: find.byType(LoftifyScrollToTopButton),
              matching: find.byType(IgnorePointer),
            )
            .first,
      )
      .ignoring;

  testWidgets('surfaces after a screen of scroll and hides near the top', (
    tester,
  ) async {
    final controller = ScrollController();
    await tester.pumpWidget(host(controller));
    await tester.pump();

    expect(visible(tester), isFalse);

    controller.jumpTo(900);
    await tester.pump();
    expect(visible(tester), isTrue);

    controller.jumpTo(100);
    await tester.pump();
    expect(visible(tester), isFalse);
  });

  testWidgets('tap rides smoothly back to the top and hides again', (
    tester,
  ) async {
    final controller = ScrollController();
    await tester.pumpWidget(host(controller));
    controller.jumpTo(1200);
    await tester.pump();
    expect(visible(tester), isTrue);

    await tester.tap(find.byType(LoftifyScrollToTopButton));
    await tester.pumpAndSettle();

    expect(controller.offset, 0);
    expect(visible(tester), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mirrors to the free corner for the bottom-right dock', (
    tester,
  ) async {
    final controller = ScrollController();
    appProvider.navigationBarPlacement = NavigationBarPlacement.cornerDocked;
    addTearDown(() {
      appProvider.navigationBarPlacement = NavigationBarPlacement.centered;
    });
    await tester.pumpWidget(host(controller));
    await tester.pump();

    // The collapsed glass button owns the bottom-right corner, so the
    // scroll-to-top button must dock bottom-left instead of stacking on it.
    final center = tester.getCenter(find.byType(LoftifyScrollToTopButton));
    expect(center.dx, lessThan(200));

    appProvider.navigationBarPlacement = NavigationBarPlacement.centered;
    // Placement is read at build time; re-mount like a real shell rebuild.
    await tester.pumpWidget(host(controller));
    await tester.pump();
    final mirrored = tester.getCenter(find.byType(LoftifyScrollToTopButton));
    expect(mirrored.dx, greaterThan(600));
    expect(tester.takeException(), isNull);
  });
}
