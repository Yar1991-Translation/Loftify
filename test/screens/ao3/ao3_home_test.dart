import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Api/demo/ao3_demo.dart';
import 'package:loftify/Models/ao3_feed_entry.dart';
import 'package:loftify/Screens/AO3/ao3_home_screen.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:loftify/Utils/ao3_store.dart';
import 'package:loftify/Utils/ao3_tags.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/generated/app_localizations.dart';

/// The home page must be fully usable from local state alone: seeded shelf
/// and cached tag listings, with no network in sight.
void main() {
  late Box ao3;

  setUpAll(() async {
    final directory = Directory('build/test_hive/ao3_home');
    await directory.create(recursive: true);
    Hive.init(directory.absolute.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
    ao3 = await Hive.openBox(HiveUtil.ao3Box);
  });

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: LoftifyTheme.build(ChewieThemeColorData.defaultLightThemes.first),
      localizationsDelegates: const [
        ChewieLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh', 'CN'),
      home: Builder(builder: (context) {
        chewieProvider.setRootContext(context);
        return const Ao3HomeScreen();
      }),
    ));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('renders from the shelf and cache, then from nothing',
      (tester) async {
    final store = Ao3Store(box: ao3);
    await tester.runAsync(() async {
      await store.save(Ao3Demo.sample(9001));
      await store.updateProgress(9001, 2);
      await Ao3Tags.follow('Fluff');
      await Ao3Tags.writeFeed('Fluff', const [
        Ao3FeedEntry(
          workId: 9002,
          title: 'Feed work',
          author: 'writer',
          updatedAtMs: 1791485054000,
          summaryText: 'excerpt',
        ),
      ]);
    });

    await pumpHome(tester);

    expect(find.text('继续阅读'), findsOneWidget);
    expect(find.text('Feed work'), findsOneWidget);
    expect(find.text('关注标签'), findsOneWidget);
    expect(find.text('最新动态'), findsOneWidget);
    expect(find.text('热门圈子'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
