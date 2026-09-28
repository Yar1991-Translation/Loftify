import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
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
      home: Scaffold(
        body: Stack(
          children: [
            ListView(
              controller: controller,
              children: [
                for (var i = 0; i < 40; i++)
                  SizedBox(height: 100, child: Text('Row $i')),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: LoftifyScrollToTopButton(scrollController: controller),
            ),
          ],
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
}
