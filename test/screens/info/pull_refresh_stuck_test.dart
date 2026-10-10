import 'dart:io';
import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Info/history_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/lottie_files.dart';
import 'package:loftify/Utils/request_util.dart';
import 'package:loftify/Widgets/Design/loftify_state_view.dart';
import 'package:loftify/generated/app_localizations.dart';

class _Cookies extends Fake implements CookieManager {}

void main() {
  final pending = <RequestInterceptorHandler>[];
  final options = <RequestOptions>[];
  setUpAll(() async {
    final dir = Directory('build/test_hive/pull_refresh_stuck');
    await dir.create(recursive: true);
    Hive.init(dir.absolute.path);
    await Hive.openBox(ChewieHiveUtil.settingsBox);
    await ChewieHiveUtil.put(HiveUtil.userInfoKey, {
      'blogId': 1,
      'blogName': 'author',
      'bigAvaImg': '',
      'homePageUrl': '',
      'imageDigitStamp': false,
      'imageProtected': false,
      'imageStamp': false,
      'isOriginalAuthor': false,
    });
    RequestUtil.cookieManager = _Cookies();
    appProvider.token = 'test-account';
    chewieProvider.stateWidgetBuilder = LoftifyStateView.fromChewie;
    EasyRefresh.defaultFooterBuilder = () => LottieCupertinoFooter(
          backgroundColor: Colors.transparent,
          indicator: LottieFiles.buildLoadingAnimation(36, false),
          triggerOffset: 52,
          maxOverOffset: 76,
          infiniteOffset: 240,
          radius: 18,
        );
    EasyRefresh.defaultHeaderBuilder = () => LottieCupertinoHeader(
          backgroundColor: Colors.transparent,
          indicator: LottieFiles.buildLoadingAnimation(40, false),
          triggerOffset: 56,
          maxOverOffset: 84,
          radius: 20,
        );
  });
  setUp(() {
    pending.clear();
    options.clear();
    RequestUtil.instance.dio.interceptors.clear();
    RequestUtil.instance.dio.interceptors
        .add(InterceptorsWrapper(onRequest: (request, handler) {
      options.add(request);
      pending.add(handler);
    }));
  });

  void respond(int index, Map<String, dynamic> data) => pending[index]
      .resolve(Response(requestOptions: options[index], data: data));

  Map<String, dynamic> historyBody() => {
        'meta': {'status': 200},
        'response': {
          'count': 1,
          'recordHistory': 1,
          'archiveData': [
            {'count': 1, 'desc': 'Previous', 'startTime': 0, 'endTime': 1},
          ],
          'items': [
            {
              'post': {'id': 99}
            }
          ],
        },
      };

  testWidgets('manual pull-to-refresh completes on a real screen',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      navigatorKey: chewieProvider.globalNavigatorKey,
      locale: const Locale('en'),
      theme: ChewieThemeColorData.defaultLightThemes.first.toThemeData(),
      localizationsDelegates: const [
        ChewieLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // Device-like safe area: the header trigger includes safeOffset.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 47),
        ),
        child: child!,
      ),
      home: Builder(builder: (context) {
        chewieProvider.setRootContext(context);
        return const HistoryScreen();
      }),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Let the refreshOnStart request finish first.
    expect(pending, isNotEmpty);
    respond(0, historyBody());
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    final log = <String>[];
    EasyRefreshData probe() =>
        EasyRefresh.of(tester.element(find.byType(Scrollable).first));

    // Manual pull past the trigger and release.
    await tester.timedDrag(
      find.byType(Scrollable).first,
      const Offset(0, 400),
      const Duration(milliseconds: 500),
    );
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      final data = probe();
      log.add('t=${(i + 1) * 100}ms mode=${data.headerNotifier.mode} '
          'offset=${data.headerNotifier.offset.toStringAsFixed(2)} '
          'trigger=${data.headerNotifier.actualTriggerOffset} '
          'requests=${pending.length}');
    }

    if (pending.length > 1) {
      respond(1, historyBody());
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        final data = probe();
        log.add('post t=${(i + 1) * 100}ms mode=${data.headerNotifier.mode} '
            'offset=${data.headerNotifier.offset.toStringAsFixed(2)}');
      }
    }

    // ignore: avoid_print
    print(log.join('\n'));
    final data = probe();
    expect(data.headerNotifier.mode, IndicatorMode.inactive,
        reason: 'header must roll back to idle after the refresh');
  });
}
