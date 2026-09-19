import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Setting/tagshield_setting_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/request_util.dart';
import 'package:loftify/Widgets/Item/setting_management_item.dart';
import 'package:loftify/generated/app_localizations.dart';
import 'package:loftify/l10n/l10n.dart';

class _UnusedCookieManager extends Fake implements CookieManager {}

const _otomePreset = ['乙女', '乙女向', '乙女游戏', '乙女ゲーム', '乙游'];

void main() {
  setUpAll(() async {
    final dir = Directory('build/test_hive/tagshield_otome');
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

  Future<void> mount(WidgetTester tester, Widget screen) async {
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
        return screen;
      }),
    ));
    await frames(tester);
  }

  testWidgets('one-tap otome filter adds the preset shield tags', (
    tester,
  ) async {
    final added = <String>[];
    RequestUtil.instance.dio.interceptors.clear();
    RequestUtil.instance.dio.interceptors
        .add(InterceptorsWrapper(onRequest: (request, handler) {
      if (request.path.contains('forbidtagsmanage')) {
        final data = request.data;
        if (data is Map && data['optype'] == 'add') {
          added.add(data['tag'] as String);
        }
        handler.resolve(Response<dynamic>(
          requestOptions: request,
          statusCode: 200,
          data: {
            'meta': {'status': 200, 'desc': 'ok'},
            if (data is Map && data['optype'] == 'get')
              'response': {'list': <String>[]},
          },
        ));
      } else {
        handler.resolve(Response<dynamic>(
          requestOptions: request,
          statusCode: 200,
          data: const {'meta': {'status': 200}},
        ));
      }
    }));

    await mount(tester, const TagShieldSettingScreen());

    Finder otomeItem() => find.byWidgetPredicate(
          (widget) =>
              widget is SettingManagementItem &&
              widget.title == appLocalizations.oneClickOtomeFilter,
        );
    expect(otomeItem(), findsOneWidget);
    expect(
      find.textContaining('乙女向', findRichText: true),
      findsWidgets,
      reason: 'the preset tag list is previewed in the description',
    );

    await tester.tap(
      find.descendant(
        of: otomeItem(),
        matching: find.byType(RoundIconTextButton),
      ),
    );
    await frames(tester);
    expect(find.text(appLocalizations.confirm), findsOneWidget);

    await tester.tap(find.text(appLocalizations.confirm));
    await frames(tester);

    expect(added, containsAll(_otomePreset));
    for (final tag in _otomePreset) {
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SettingManagementItem && widget.title == tag,
        ),
        findsOneWidget,
        reason: '$tag should appear as a shielded row',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('second run reports that the tags are already shielded', (
    tester,
  ) async {
    RequestUtil.instance.dio.interceptors.clear();
    RequestUtil.instance.dio.interceptors
        .add(InterceptorsWrapper(onRequest: (request, handler) {
      final data = request.data;
      handler.resolve(Response<dynamic>(
        requestOptions: request,
        statusCode: 200,
        data: {
          'meta': {'status': 200, 'desc': 'ok'},
          if (data is Map && data['optype'] == 'get')
            'response': {'list': List<String>.from(_otomePreset)},
        },
      ));
    }));

    await mount(tester, const TagShieldSettingScreen());

    await tester.tap(
      find.descendant(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is SettingManagementItem &&
              widget.title == appLocalizations.oneClickOtomeFilter,
        ),
        matching: find.byType(RoundIconTextButton),
      ),
    );
    await frames(tester);

    // No confirm dialog should appear; the toast path is taken instead.
    expect(find.text(appLocalizations.confirm), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
