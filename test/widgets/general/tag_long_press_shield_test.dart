import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/request_util.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';
import 'package:loftify/generated/app_localizations.dart';
import 'package:loftify/l10n/l10n.dart';

class _UnusedCookieManager extends Fake implements CookieManager {}

void main() {
  setUpAll(() async {
    final dir = Directory('build/test_hive/tag_long_press');
    await dir.create(recursive: true);
    Hive.init(dir.absolute.path);
    await Hive.openBox(ChewieHiveUtil.settingsBox);
    RequestUtil.cookieManager = _UnusedCookieManager();
    appProvider.token = 'test-account';
  });

  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('long-pressing a tag chip offers to shield that tag', (
    tester,
  ) async {
    final addedTags = <String>[];
    RequestUtil.instance.dio.interceptors.clear();
    RequestUtil.instance.dio.interceptors
        .add(InterceptorsWrapper(onRequest: (request, handler) {
      final data = request.data;
      if (data is Map && data['optype'] == 'add') {
        addedTags.add(data['tag'] as String);
      }
      handler.resolve(Response<dynamic>(
        requestOptions: request,
        statusCode: 200,
        data: const {
          'meta': {'status': 200, 'desc': 'ok'},
        },
      ));
    }));

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      navigatorKey: chewieProvider.globalNavigatorKey,
      theme: ChewieThemeColorData.defaultLightThemes.first.toThemeData(),
      localizationsDelegates: const [
        ChewieLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        chewieProvider.setRootContext(context);
        return Scaffold(
          body: Center(
            child: ItemBuilder.buildTagItem(
              context,
              '测试标签',
              TagType.normal,
              jumpToTag: false,
            ),
          ),
        );
      }),
    ));
    await frames(tester);

    expect(find.text('#测试标签'), findsOneWidget);
    await tester.longPress(find.text('#测试标签'));
    await frames(tester);

    expect(find.text(appLocalizations.shieldThisTag), findsWidgets);
    await tester.tap(find.text(appLocalizations.addShieldTag));
    await frames(tester);

    expect(addedTags, contains('测试标签'));
    expect(tester.takeException(), isNull);
  });
}
