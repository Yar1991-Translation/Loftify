import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Models/ao3_work.dart';
import 'package:loftify/Screens/AO3/ao3_reader_screen.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:loftify/Utils/ao3_store.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/generated/app_localizations.dart';

class _NoWriteStore extends Ao3Store {
  _NoWriteStore({required super.box});
  @override
  Future<void> updateProgress(int id, int chapterIndex) async {}
}

Ao3Work _workWith(String body) => Ao3Work(
      id: 5001,
      title: 'Probe work',
      author: 'tester',
      authorUrl: '',
      language: 'English',
      publishedAt: '2026-01-01',
      chapters: [
        Ao3Chapter(index: 1, title: 'Chapter 1', bodyHtml: body),
      ],
    );

void main() {
  late Box ao3;

  setUpAll(() async {
    final directory = Directory('build/test_hive/ao3_body_probe');
    await directory.create(recursive: true);
    Hive.init(directory.absolute.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
    ao3 = await Hive.openBox(HiveUtil.ao3Box);
  });

  Future<void> pump(WidgetTester tester) async {
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
        return Ao3ReaderScreen(workId: 5001, store: _NoWriteStore(box: ao3));
      }),
    ));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  for (final size in [120, 200, 400]) {
    testWidgets('renders a body of ' + size.toString() + ' paragraphs',
        (tester) async {
      final body = List.generate(
        size,
        (i) => '<p>Paragraph ' + i.toString() +
            ' carries enough words to need a couple of lines when laid out on a phone.</p>',
      ).join();
      await tester.runAsync(() => Ao3Store(box: ao3).save(_workWith(body)));
      await pump(tester);
      final richCount = find.byType(RichText).evaluate().length;
      final found = find
          .textContaining('Paragraph 5 ', findRichText: true)
          .evaluate()
          .length;
      // ignore: avoid_print
      print('RESULT size=' + size.toString() + ' chars=' + body.length.toString() +
          ' richTexts=' + richCount.toString() + ' found=' + found.toString());
      expect(tester.takeException(), isNull);
    });
  }
}
