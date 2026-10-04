import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Api/demo/ao3_demo.dart';
import 'package:loftify/Screens/AO3/ao3_reader_screen.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:loftify/Utils/ao3_config.dart';
import 'package:loftify/Utils/ao3_store.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/generated/app_localizations.dart';

/// The reader renders from the offline shelf only — no test here may touch
/// the network, which is also what proves the cache-hit path works.
class _NoWriteStore extends Ao3Store {
  _NoWriteStore({required super.box});

  @override
  Future<void> updateProgress(int id, int chapterIndex) async {}
}
void main() {
  late Box box;

  setUpAll(() async {
    final directory = Directory('build/test_hive/ao3_reader');
    await directory.create(recursive: true);
    Hive.init(directory.absolute.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
    box = await Hive.openBox(HiveUtil.ao3Box);
  });

  setUp(() async {
    await box.clear();
    Ao3Config.saveCacheLimit(50);
  });

  /// The reader writes progress on open; inside a widget test that Hive write
  /// never completes (fake async), and a stuck write would block the next
  /// test's box. Inject a store that skips persistence.
  Ao3Store readOnlyStore() => _NoWriteStore(box: box);

  Future<void> pumpReader(WidgetTester tester, int workId) async {
    tester.view.physicalSize = const Size(900, 1600);
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
      locale: const Locale('en'),
      home: Builder(builder: (context) {
        chewieProvider.setRootContext(context);
        return Ao3ReaderScreen(workId: workId, store: readOnlyStore());
      }),
    ));
    // Bounded pumping: an ambient animation must not be able to hang the test.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    // Chapter HTML is rendered asynchronously, so let real async work run
    // before pumping the result in.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('renders a cached work without touching the network',
      (tester) async {
    final work = Ao3Demo.sample(4242);
    // Hive writes real files, which never finish inside the fake-async zone a
    // widget test runs in; seed the shelf for real first.
    await tester.runAsync(() => Ao3Store(box: box).save(work));

    await pumpReader(tester, 4242);

    expect(find.text(work.title), findsWidgets);
    expect(find.textContaining('第一章'), findsWidgets);
    expect(find.textContaining('Chapter 1/2'), findsWidgets);
    // Chapter bodies go through flutter_widget_from_html, which renders rich
    // text rather than a plain Text widget.
    expect(
      find.textContaining('演示正文', findRichText: true),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the stored chapter when re-opened', (tester) async {
    final store = Ao3Store(box: box);
    await tester.runAsync(() async {
      await store.save(Ao3Demo.sample(555));
      await store.updateProgress(555, 2);
    });

    await pumpReader(tester, 555);

    expect(find.textContaining('Chapter 2/2'), findsWidgets);
    expect(find.textContaining('第二章'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
