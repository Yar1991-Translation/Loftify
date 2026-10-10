import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Guards the desktop shell layout: the window buttons live in the caption
/// strip that main_screen renders above the panel, so an app bar must start
/// below them and keep only a hairline trailing inset — the field inside it
/// is then centred against the sidebar instead of ending short of the edge.
void main() {
  setUpAll(() async {
    final hiveDirectory = Directory(
      '${Directory.current.path}/build/test_hive/desktop_app_bar_layout',
    );
    await hiveDirectory.create(recursive: true);
    Hive.init(hiveDirectory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('desktop landscape app bar keeps a hairline trailing inset',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: ChewieThemeColorData.defaultLightThemes.first.toThemeData(),
      home: Builder(builder: (context) {
        chewieProvider.setRootContext(context);
        return const Scaffold(
          appBar: ResponsiveAppBar(
            titleWidget: SizedBox(
              key: ValueKey('app-bar-field'),
              height: 40,
            ),
            titleLeftMargin: 0,
            rightSpacing: 0,
          ),
          body: SizedBox.expand(),
        );
      }),
    ));
    await tester.pumpAndSettle();

    final bar = tester.getRect(find.byType(ResponsiveAppBar));
    final field = tester.getRect(find.byKey(const ValueKey('app-bar-field')));

    expect(bar.width, 1280);
    // 8 on desktop; the former window-button footprint (152) must not return.
    expect(bar.right - field.right, 8);
    expect(field.left - bar.left, 0);
  });

  test('desktop body renders the window buttons in their own caption strip',
      () {
    final source = File('lib/Screens/main_screen.dart').readAsStringSync();
    final body = source.split('_buildDesktopBody() {')[1];

    expect(source, contains('static const double _windowCaptionHeight = 44;'));
    // Panel content comes after the caption strip, never underneath it.
    expect(body.indexOf('_windowCaptionHeight'), greaterThan(-1));
    expect(body.indexOf('PanelScreen(key: panelScreenKey)'),
        greaterThan(body.indexOf('_windowCaptionHeight')));
    // The strip is desktop chrome only; the web build shares this body.
    expect(body, contains('ResponsiveUtil.isDesktop()'));
  });
}
