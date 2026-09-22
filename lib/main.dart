import 'dart:async';
import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:loftify/Api/demo/demo_mode.dart';
import 'package:loftify/Database/database_manager.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/cloud_control_provider.dart';
import 'package:loftify/Utils/display_mode_util.dart';
import 'package:loftify/Utils/download_task_manager.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/loftify_file_util.dart';
import 'package:loftify/Utils/lottie_files.dart';
import 'package:loftify/Utils/request_header_util.dart';
import 'package:loftify/Utils/request_util.dart';
import 'package:loftify/Utils/uri_util.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:provider/provider.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:window_manager/window_manager.dart';

import 'Screens/Lock/pin_verify_screen.dart';
import 'Screens/main_screen.dart';
import 'generated/app_localizations.dart';
import 'l10n/l10n.dart';

const List<String> kWindowsSchemes = ["lofter"];

/// Test switch: run the portrait phone layout on desktop builds
/// (--dart-define=FORCE_MOBILE_LAYOUT=true).
const bool kForceMobileLayout = bool.fromEnvironment('FORCE_MOBILE_LAYOUT');

Future<void> main(List<String> args) async {
  runMyApp(args);
}

Future<void> runMyApp(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initLocaleData();
  ResponsiveUtil.forceMobileLayout = kForceMobileLayout;
  await initApp();
  if (DemoMode.enabled) {
    DemoMode.seedDemoLogin();
  } else {
    DemoMode.restoreRealLoginIfStale();
  }
  chewieProvider.loadingWidgetBuilder = LottieFiles.buildLoadingAnimation;
  if (ResponsiveUtil.isAndroid()) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await initDisplayMode();
    await RequestHeaderUtil.initAndroidInfo();
  }
  if (ResponsiveUtil.isDesktop()) {
    await initWindow();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
    );
    await launchAtStartup.enable();
    await launchAtStartup.disable();
    await LocalNotifier.instance.setup(
      appName: packageInfo.appName,
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
    ChewieHiveUtil.put(HiveUtil.launchAtStartupKey,
        await LaunchAtStartup.instance.isEnabled());
    for (String scheme in kWindowsSchemes) {
      await protocolHandler.register(scheme);
    }
    await HotKeyManager.instance.unregisterAll();
  }
  StatefulWidget home;
  if (HiveUtil.shouldAutoLock()) {
    home = const PinVerifyScreen(
      isModal: true,
      jumpToMain: true,
      showWindowTitle: true,
      autoAuth: true,
    );
  } else {
    home = MainScreen(key: mainScreenKey);
  }
  runApp(MyApp(home: home));
  FlutterNativeSplash.remove();
}

/// intl 的日期符号不随应用内嵌：对未加载数据的 locale 创建 DateFormat 会
/// 抛 LocaleDataException。若它发生在 runApp 之前，启动链会静默中断、
/// 永远卡在原生闪屏（HyperOS 3 平板实测：FlutterDisplayMode 报错 →
/// ILogger 的 DateFormat 抛错 → runMyApp 整体挂掉）。启动最早期预载
/// 全部支持 locale 的数据。
Future<void> _initLocaleData() async {
  for (final locale in AppLocalizations.supportedLocales) {
    try {
      await initializeDateFormatting(locale.toString(), null);
    } catch (_) {
      // 缺数据绝不能阻塞启动；en_US 是 intl 内嵌的兜底 locale。
    }
  }
}

Future<void> initApp() async {
  FlutterError.onError = onError;
  imageCache.maximumSizeBytes = 1024 * 1024 * 1024 * 2;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 1024 * 2;
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);
  await DatabaseManager.getDataBase();
  // Hive.defaultDirectory = await FileUtil.getApplicationDir();
  await HiveUtil.initBox();
  await ResponsiveUtil.init();
  LoftifyFileUtil.configureDownloadDelegates();
  await DownloadTaskManager.instance.initialize();
  await RequestUtil.init();
  UriUtil.processUrl = LoftifyUriUtil.processUrl;
}

Future<void> initWindow() async {
  await windowManager.ensureInitialized();
  Offset position = ChewieHiveUtil.getWindowPosition();
  WindowOptions windowOptions = WindowOptions(
    size: ChewieHiveUtil.getWindowSize(),
    minimumSize: ChewieProvider.minimumWindowSize,
    center: position == Offset.zero,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    if (position != Offset.zero) await windowManager.setPosition(position);
  });
}

Future<void> initDisplayMode() async {
  try {
    final modes = await FlutterDisplayMode.supported;
    ILogger.info("Supported display modes: $modes");
    final activeMode = await FlutterDisplayMode.active;
    final preferredMode = await FlutterDisplayMode.preferred;
    ILogger.info(
        "Current active display mode: $activeMode\nCurrent preferred display mode: $preferredMode");
    final legacyIndex =
        ChewieHiveUtil.getInt(HiveUtil.refreshRateKey, defaultValue: -1);
    final encodedMode = ChewieHiveUtil.getString(HiveUtil.refreshRateModeKey);
    final configMode = DisplayModePreference.resolve(
      modes: modes,
      activeMode: activeMode,
      encodedMode: encodedMode,
      legacyIndex: legacyIndex,
    );
    if ((encodedMode == null || encodedMode.isEmpty) && legacyIndex >= 0) {
      await ChewieHiveUtil.put(
        HiveUtil.refreshRateModeKey,
        DisplayModePreference.encode(configMode),
      );
      await ChewieHiveUtil.delete(HiveUtil.refreshRateKey);
    }
    await DisplayModeController.setPreferredMode(configMode);
    ILogger.info("Config display mode: $configMode");
    ILogger.info(
        "Current active display mode after config: ${await FlutterDisplayMode.active}\nCurrent preferred display mode after config: ${await FlutterDisplayMode.preferred}");
  } catch (e, t) {
    ILogger.error("Failed to init display mode", e, t);
  }
}

Future<void> onError(FlutterErrorDetails details) async {
  try {
    File errorFile = File(join(await FileUtil.getLogDir(), "error.log"));
    if (!errorFile.existsSync()) errorFile.createSync();
    errorFile.writeAsStringSync(
        "${details.exceptionAsString()}\n${details.stack}",
        mode: FileMode.append);
    if (details.stack != null) {
      Zone.current.handleUncaughtError(details.exception, details.stack!);
    }
  } catch (e, t) {
    ILogger.error("Failed to write error log", e, t);
  }
}

class MyApp extends StatefulWidget {
  final Widget home;
  final String title;

  const MyApp({
    super.key,
    required this.home,
    this.title = 'Loftify',
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    appProvider.refreshSystemLocale();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    appProvider.refreshSystemLocale();
  }

  @override
  void didChangePlatformBrightness() {
    appProvider.refreshSystemTheme();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appProvider),
        ChangeNotifierProvider.value(value: chewieProvider),
        ChangeNotifierProvider.value(value: controlProvider),
      ],
      child: Selector<AppProvider,
          ({ThemeMode themeMode, Locale? locale, Brightness platformBrightness, Locale platformLocale, Object lightTheme, Object darkTheme})>(
        // MaterialApp only depends on theme/appearance inputs. Selecting a
        // narrow record keeps high-frequency notifications (tab switches,
        // panel pushes, token updates) from rebuilding the whole app tree
        // mid-animation. Platform brightness/locale are included so
        // "follow system" changes still rebuild; theme data objects are
        // compared by identity and only recreated on real theme changes.
        selector: (context, provider) => (
              themeMode: provider.themeMode.themeMode,
              locale: provider.locale,
              platformBrightness: WidgetsBinding
                  .instance.platformDispatcher.platformBrightness,
              platformLocale: WidgetsBinding.instance.platformDispatcher.locale,
              lightTheme: provider.lightTheme,
              darkTheme: provider.darkTheme,
            ),
        builder: (context, appearance, child) => MaterialApp(
          navigatorKey: chewieProvider.globalNavigatorKey,
          navigatorObservers: [chewieProvider.routeObserver],
          title: widget.title,
          themeMode: appearance.themeMode,
          theme: LoftifyTheme.build(appProvider.lightTheme),
          darkTheme: LoftifyTheme.build(appProvider.darkTheme),
          debugShowCheckedModeBanner: false,
          // Opt-in frame-time overlay for profiling sessions:
          // flutter run --profile --dart-define=PERF_OVERLAY=true
          showPerformanceOverlay: const bool.fromEnvironment('PERF_OVERLAY'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ChewieLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: appearance.locale ?? resolveSystemAppLocale(),
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: (locale, supportedLocales) {
            try {
              if (appearance.locale != null) {
                return appearance.locale;
              }
              return resolveAppLocale(
                WidgetsBinding.instance.platformDispatcher.locale,
              );
            } catch (e, t) {
              ILogger.error("Failed to load locale", e, t);
              return const Locale("zh", "CN");
            }
          },
          home: CustomMouseRegion(child: widget.home),
          builder: (context, widget) {
            final systemUiOverlayStyle =
                AppBarWrapper.systemUiOverlayStyleForBrightness(
              Theme.of(context).brightness,
              includeNavigationBar: true,
            );
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: systemUiOverlayStyle,
              child: Overlay(
                initialEntries: [
                  if (widget != null) ...[
                    OverlayEntry(
                      builder: (overlayContext) {
                        chewieProvider.setRootContext(
                          chewieProvider.globalNavigatorState?.context ??
                              overlayContext,
                        );
                        return Listener(
                          onPointerDown: (_) {
                            if (!ResponsiveUtil.isDesktop() &&
                                searchScreenState?.hasSearchFocus == true) {
                              FocusManager.instance.primaryFocus?.unfocus();
                            }
                          },
                          child: widget,
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
