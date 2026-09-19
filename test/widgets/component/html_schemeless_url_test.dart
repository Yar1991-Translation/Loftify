import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

Future<void> pumpHost(WidgetTester tester, String content) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light(),
      home: Builder(
        builder: (context) {
          // CustomHtmlWidget resolves ChewieTheme through the global
          // rootContext, so register a context that stays alive in this tree.
          chewieProvider.setRootContext(context);
          return Scaffold(
            body: SingleChildScrollView(
              child: CustomHtmlWidget(
                content: content,
                url: 'https://www.lofter.com/post/abc',
                showLoading: false,
              ),
            ),
          );
        },
      ),
    ),
  );
  // A couple of frames are enough for the synchronous HTML build; never use
  // pumpAndSettle here — network image retries schedule frames forever.
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/html_schemeless_url',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  group('WebUtil.sanitizeSchemelessHtml', () {
    test('repairs every attribute flavour that can carry a URL', () {
      expect(
        WebUtil.sanitizeSchemelessHtml('<img src="://x/a.jpg">'),
        '<img src="https://x/a.jpg">',
      );
      expect(
        WebUtil.sanitizeSchemelessHtml("<a href='://x'>l</a>"),
        "<a href='https://x'>l</a>",
      );
      expect(
        WebUtil.sanitizeSchemelessHtml(
          '<img data-src="://x/a.jpg" data-original="://x/b.jpg">',
        ),
        '<img data-src="https://x/a.jpg" data-original="https://x/b.jpg">',
      );
      expect(
        WebUtil.sanitizeSchemelessHtml(
          '<video poster="://x/p.jpg"><source src="://x/a.mp4"></video>',
        ),
        '<video poster="https://x/p.jpg"><source src="https://x/a.mp4"></video>',
      );
      expect(
        WebUtil.sanitizeSchemelessHtml('src=://x/unquoted'),
        'src=https://x/unquoted',
      );
      expect(
        WebUtil.sanitizeSchemelessHtml('SRC="://x/a.jpg"'),
        'SRC="https://x/a.jpg"',
      );
    });

    test('repairs scheme-less css url() references', () {
      expect(
        WebUtil.sanitizeSchemelessHtml(
          'background-image: url(\'://x/a.jpg\')',
        ),
        'background-image: url(\'https://x/a.jpg\')',
      );
      expect(
        WebUtil.sanitizeSchemelessHtml('background-image: url(://x/a.jpg)'),
        'background-image: url(https://x/a.jpg)',
      );
    });

    test('leaves well-formed content untouched', () {
      final html =
          '<p>ok</p><img src="https://x/a.jpg"><a href="#tag">t</a>'
          '<a href="/relative">r</a>';
      expect(WebUtil.sanitizeSchemelessHtml(html), html);
    });
  });

  testWidgets('img with empty scheme renders without error box', (
    tester,
  ) async {
    await pumpHost(
      tester,
      '<p>before</p><img src="://imglf1.lf127.net/img/a.jpg" /><p>after</p>',
    );
    expect(find.textContaining('Error rendering content'), findsNothing);
    expect(find.textContaining('before', findRichText: true), findsOneWidget);
  });

  testWidgets('link with empty scheme renders without error box', (
    tester,
  ) async {
    await pumpHost(
      tester,
      '<p>see <a href="://example.com/x">this link</a></p>',
    );
    expect(find.textContaining('Error rendering content'), findsNothing);
    expect(find.textContaining('this link', findRichText: true), findsOneWidget);
  });

  testWidgets('bare "://" in img renders without error box', (tester) async {
    await pumpHost(tester, '<p>t</p><img src="://" /><p>u</p>');
    expect(find.textContaining('Error rendering content'), findsNothing);
    expect(find.textContaining('u', findRichText: true), findsOneWidget);
  });

  testWidgets('protocol-relative img renders without error box', (
    tester,
  ) async {
    await pumpHost(tester, '<img src="//imglf1.lf127.net/img/a.jpg" />');
    expect(find.textContaining('Error rendering content'), findsNothing);
  });
}
