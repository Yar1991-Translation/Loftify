import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:loftify/Api/server_api.dart';
import 'package:loftify/Screens/Login/login_by_captcha_screen.dart';
import 'package:loftify/Screens/panel_screen.dart';
import 'package:loftify/Utils/cloud_control_provider.dart';
import 'package:loftify/Utils/lottie_files.dart';
import 'package:loftify/Widgets/Design/loftify_state_view.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';
import 'package:loftify/Widgets/Navigation/loftify_navigation_rail.dart';
import 'package:loftify/Widgets/loftify_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../l10n/l10n.dart';
import '../Api/login_api.dart';
import '../Api/user_api.dart';
import '../Models/account_response.dart';
import '../Utils/ao3_nav.dart';
import '../Utils/app_provider.dart';
import '../Utils/clipboard_link_controller.dart';
import '../Utils/enums.dart';
import '../Utils/hive_util.dart';
import '../Utils/feedback.dart';
import '../Utils/uri_util.dart';
import '../Utils/utils.dart';
import '../Widgets/Dialog/clipboard_link_dialog.dart';
import '../Widgets/Design/loftify_lottie.dart';
import 'Info/system_notice_screen.dart';
import 'Info/user_detail_screen.dart';
import 'Lock/pin_verify_screen.dart';
import 'Setting/setting_screen.dart';
import 'Suit/suit_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const String routeName = "/";

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends BaseWindowState<MainScreen>
    with
        WidgetsBindingObserver,
        TickerProviderStateMixin,
        TrayListener,
        AutomaticKeepAliveClientMixin {
  Timer? _timer;
  Timer? _clipboardTimer;
  late final ClipboardLinkController _clipboardLinks;
  late AnimationController darkModeController;
  Widget? darkModeWidget;
  FullBlogInfo? blogInfo;
  bool _hasJumpedToPinVerify = false;
  bool _orientationPolicyUpdateScheduled = false;
  Orientation? _oldOrientation;

  @override
  void onWindowMinimize() {
    setTimer();
    super.onWindowMinimize();
  }

  @override
  void onWindowRestore() {
    super.onWindowRestore();
    cancleTimer();
  }

  @override
  void onWindowFocus() {
    cancleTimer();
    super.onWindowFocus();
    _scheduleClipboardCheck();
  }

  @override
  void onWindowEvent(String eventName) {
    super.onWindowEvent(eventName);
    if (eventName == "hide") {
      setTimer();
    }
  }

  /// Clipboard reads are debounced: focus and lifecycle events can arrive in
  /// bursts, and the dialog must not open twice for one copy.
  void _scheduleClipboardCheck() {
    _clipboardTimer?.cancel();
    _clipboardTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) unawaited(_clipboardLinks.check());
    });
  }

  _fetchUserInfo() async {
    if (appProvider.token.isNotEmpty) {
      return await UserApi.getUserInfo().then((value) async {
        try {
          if (value['meta']['status'] != 200) {
            IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
            return IndicatorResult.fail;
          } else {
            AccountResponse accountResponse =
                AccountResponse.fromJson(value['response']);
            await HiveUtil.setUserInfo(accountResponse.blogs[0].blogInfo);
            await ChewieHiveUtil.put(
                HiveUtil.userIdKey, accountResponse.blogs[0].blogInfo?.blogId);
            setState(() {
              blogInfo = accountResponse.blogs[0].blogInfo;
            });
            return IndicatorResult.success;
          }
        } catch (e, t) {
          ILogger.error("Failed to load user info", e, t);
          if (mounted) IToast.showTop(appLocalizations.loadFailed);
          return IndicatorResult.fail;
        } finally {}
      });
    }
    if (mounted) setState(() {});
    return IndicatorResult.success;
  }

  Future<void> initDeepLinks() async {
    final appLinks = AppLinks();
    appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        UriUtil.processUrl(context, uri.toString(), pass: false);
      }
    }, onError: (Object err) {
      ILogger.error('Failed to get URI: $err');
    });
  }

  login() {
    dialogNavigatorState?.popAll();
    panelScreenState?.login();
    _fetchUserInfo();
  }

  logout() {
    panelScreenState?.logout();
    blogInfo = null;
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _clipboardLinks = ClipboardLinkController(
      canPrompt: () =>
          mounted &&
          !_hasJumpedToPinVerify &&
          (WidgetsBinding.instance.lifecycleState == null ||
              WidgetsBinding.instance.lifecycleState ==
                  AppLifecycleState.resumed) &&
          (ModalRoute.of(context)?.isCurrent ?? false),
      confirm: (url) => ClipboardLinkDialog.show(
        context,
        url,
        isAo3: LoftifyUriUtil.isAo3WorkUrl(url),
      ),
      open: (url) async {
        await UriUtil.processUrl(context, url, pass: false);
      },
    );
    windowManager.addListener(this);
    WidgetsBinding.instance.addObserver(this);
    darkModeController = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      jumpToLogin();
      _scheduleClipboardCheck();
      _maybeShowDevFeedbackPrompt();
      darkModeWidget = LottieFiles.buildAnimation(
        LottieFiles.sunLight,
        size: 25,
        autoForward: !ColorUtil.isDark(context),
        controller: darkModeController,
      );
      ResponsiveUtil.runByPlatform(desktop: () async {
        await Utils.initTray();
        trayManager.addListener(this);
        appProvider.shortcutFocusNode.requestFocus();
      });
      // Parse the heavy interaction Lotties (700KB+ JSON) in background
      // isolates during idle time so the first like / celebration plays
      // without a stall.
      Future.delayed(const Duration(seconds: 3), () {
        LoftifyLottie.prewarm([
          LottieFiles.likeMediumDark,
          LottieFiles.likeMediumLight,
          LottieFiles.likeDoubleClickDark,
          LottieFiles.likeDoubleClickLight,
          LottieFiles.likeDoubleTap,
          LottieFiles.celebrate,
        ]);
      });
    });
    initConfig();
    fetchBasicData();
    fetchData();
  }

  /// Development builds introduce themselves once per version: testers get
  /// the QQ group without hunting for it, and stable builds stay silent.
  Future<void> _maybeShowDevFeedbackPrompt() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version;
      if (!version.contains('-dev')) return;
      const seenKey = 'devFeedbackPromptVersion';
      if (ChewieHiveUtil.getString(seenKey) == version) return;
      await ChewieHiveUtil.put(seenKey, version);
      if (!mounted || _hasJumpedToPinVerify) return;
      if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
      await DialogBuilder.showConfirmDialog(
        context,
        title: appLocalizations.qqFeedbackTitle,
        message: appLocalizations.qqFeedbackDevPrompt(
          version,
          FeedbackChannels.qqGroup,
        ),
        confirmButtonText: appLocalizations.qqFeedbackCopyGroup,
        cancelButtonText: appLocalizations.cancel,
        onTapConfirm: () {
          Clipboard.setData(
            const ClipboardData(text: FeedbackChannels.qqGroup),
          );
          IToast.showTop(
            appLocalizations.qqFeedbackCopied(FeedbackChannels.qqGroup),
          );
        },
      );
    } catch (error, stack) {
      ILogger.error('Failed to show the dev feedback prompt', error, stack);
    }
  }

  void fetchBasicData() {
    ServerApi.getCloudControl();
    CustomFont.downloadFont(showToast: false);
    _fetchUserInfo();
    // Auto check for updates is ON by default: users only miss it if they
    // explicitly turn it off in general settings.
    if (ChewieHiveUtil.getBool(
      HiveUtil.autoCheckUpdateKey,
      defaultValue: true,
    )) {
      ChewieUtils.getReleases(
        context: context,
        showLoading: false,
        showUpdateDialog: true,
        showFailedToast: false,
        showLatestToast: false,
      );
    }
  }

  Future<void> fetchData() async {
    await LoginApi.uploadNewDevice();
    await LoginApi.autoLogin();
    await LoginApi.getConfigs();
  }

  initConfig() {
    unawaited(ResponsiveUtil.checkSizeCondition());
    ResponsiveUtil.runByPlatform(
      desktop: () {
        initHotKey();
        windowManager
            .isAlwaysOnTop()
            .then((value) => setState(() => isStayOnTop = value));
        windowManager
            .isMaximized()
            .then((value) => setState(() => isMaximized = value));
      },
      mobile: () {
        ChewieUtils.setSafeMode(ChewieHiveUtil.getBool(
            HiveUtil.enableSafeModeKey,
            defaultValue: false));
      },
    );
    initDeepLinks();
    initEasyRefresh();
  }

  initHotKey() async {
    HotKey hotKey = HotKey(
      key: PhysicalKeyboardKey.keyC,
      modifiers: [HotKeyModifier.alt],
      scope: HotKeyScope.inapp,
    );
    await hotKeyManager.register(
      hotKey,
      keyDownHandler: (hotKey) {
        RouteUtil.pushPanelCupertinoRoute(rootContext, const SettingScreen());
      },
    );
  }

  void initEasyRefresh() {
    EasyRefresh.defaultHeaderBuilder = () => LottieCupertinoHeader(
          backgroundColor: Colors.transparent,
          indicator: LottieFiles.buildLoadingAnimation(40, false),
          hapticFeedback: true,
          triggerOffset: 56,
          maxOverOffset: 84,
          radius: 20,
        );
    EasyRefresh.defaultFooterBuilder = () => LottieCupertinoFooter(
          backgroundColor: Colors.transparent,
          indicator: LottieFiles.buildLoadingAnimation(36, false),
          triggerOffset: 52,
          maxOverOffset: 76,
          infiniteOffset: 240,
          radius: 18,
        );
    chewieProvider.loadingWidgetBuilder = LottieFiles.buildLoadingAnimation;
    chewieProvider.stateWidgetBuilder = LoftifyStateView.fromChewie;
  }

  void jumpToLogin() {
    if (ChewieHiveUtil.isFirstLogin() &&
        ChewieHiveUtil.getString(HiveUtil.tokenKey, defaultValue: null) ==
            null) {
      HiveUtil.initConfig();
      ChewieHiveUtil.setFirstLogin();
      if (ResponsiveUtil.isLandscapeLayout()) {
        DialogBuilder.showPageDialog(context,
            child: const LoginByCaptchaScreen());
      } else {
        RouteUtil.pushPanelCupertinoRoute(
            context, const LoginByCaptchaScreen());
      }
    }
  }

  void jumpToLock({bool autoAuth = false}) {
    if (HiveUtil.shouldAutoLock()) {
      _hasJumpedToPinVerify = true;
      RouteUtil.pushCupertinoRoute(
          context,
          PinVerifyScreen(
            isModal: true,
            autoAuth: autoAuth,
            showWindowTitle: true,
          ), onThen: (_) {
        _hasJumpedToPinVerify = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return OrientationBuilder(builder: (context, orientation) {
      if (_oldOrientation != null && orientation != _oldOrientation) {
        // ResponsiveUtil.returnToMainScreen(context);
      }
      _oldOrientation = orientation;
      if (ResponsiveUtil.isDesktop() || ResponsiveUtil.isWeb()) {
        return _buildDesktopBody();
      }
      if (ResponsiveUtil.isTabletLayout()) {
        // Material tablet shell: NavigationRail + tab content, with no
        // window chrome — drag handles and the title bar stay desktop-only.
        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: ChewieTheme.scaffoldBackgroundColor,
          body: SafeArea(child: _buildTabletBody()),
        );
      }
      return PanelScreen(key: panelScreenKey);
    });
  }

  Widget _buildTabletBody() {
    // No divider between rail and content: the rail's
    // surfaceContainerLow separates the regions tonally (M3 spec).
    return Row(
      children: [
        _buildNavigationRail(),
        Expanded(child: PanelScreen(key: panelScreenKey)),
      ],
    );
  }

  Widget _buildNavigationRail() {
    final colorScheme = Theme.of(context).colorScheme;
    final iconButtonStyle = IconButton.styleFrom(
      foregroundColor: colorScheme.onSurfaceVariant,
    );
    return Selector<AppProvider,
        ({SideBarChoice choice, bool showNavigator})>(
      selector: (_, provider) => (
        choice: provider.sidebarChoice,
        showNavigator: provider.showPanelNavigator,
      ),
      builder: (context, state, child) => LoftifyNavigationRail(
        // A sub-page covering the tabs clears the indicator, mirroring the
        // desktop sidebar's deselection behaviour.
        choices: Ao3Nav.choices(),
        selectedIndex:
            state.showNavigator ? null : Ao3Nav.visibleIndex(state.choice),
        onDestinationSelected: (index) {
          appProvider.sidebarChoice = Ao3Nav.choiceAt(index);
          panelScreenState?.popAll(false);
        },
        trailing: [
          IconButton(
            onPressed: changeMode,
            style: iconButtonStyle,
            icon: darkModeWidget ?? emptyWidget,
          ),
          IconButton(
            onPressed: () {
              RouteUtil.pushPanelCupertinoRoute(context, const SettingScreen());
            },
            style: iconButtonStyle,
            icon: const Icon(LoftifyIcons.settings),
          ),
        ],
      ),
    );
  }

  _buildDesktopBody() {
    return Row(
      children: [
        _sideBar(leftPadding: 8, rightPadding: 8),
        Expanded(
          child: Column(
            children: [
              // The window buttons own a caption strip of their own instead of
              // floating over the panel: an app bar drawn at the very top would
              // otherwise put its field on the same line as the controls. The
              // web build shares this body but has no window chrome.
              if (ResponsiveUtil.isDesktop())
                Container(
                  height: _windowCaptionHeight,
                  color: ChewieTheme.appBarBackgroundColor,
                  child: Row(
                    children: [
                      const Expanded(child: WindowMoveHandle()),
                      _titleBar(),
                    ],
                  ),
                ),
              Expanded(child: PanelScreen(key: panelScreenKey)),
            ],
          ),
        ),
      ],
    );
  }

  _buildAvatarContextMenuButtons() {
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem(
          appLocalizations.viewPersonalHomepage,
          iconData: LoftifyIcons.profile,
          onPressed: () async {
            panelScreenState?.pushPage(UserDetailScreen(
              blogId: blogInfo!.blogId,
              blogName: blogInfo!.blogName,
            ));
          },
        ),
        FlutterContextMenuItem.divider(),
        FlutterContextMenuItem(
          appLocalizations.logout,
          status: MenuItemStatus.warning,
          iconData: LoftifyIcons.logout,
          onPressed: () async {
            HiveUtil.confirmLogout(context);
          },
        ),
      ],
    );
  }

  /// Height of the desktop caption strip that hosts the window buttons.
  /// Panel content starts below it, so an app-bar field is never level with
  /// the window controls.
  static const double _windowCaptionHeight = 44;

  _titleBar() {
    return ResponsiveUtil.selectByPlatform(
      desktop: WindowTitleWrapper(
        height: _windowCaptionHeight,
        backgroundColor: Colors.transparent,
        isStayOnTop: isStayOnTop,
        isMaximized: isMaximized,
        onStayOnTopTap: () {
          setState(() {
            isStayOnTop = !isStayOnTop;
            windowManager.setAlwaysOnTop(isStayOnTop);
          });
        },
        rightButtons: const [],
      ),
    );
  }

  changeMode() {
    if (ColorUtil.isDark(context)) {
      appProvider.themeMode = ActiveThemeMode.light;
      darkModeController.forward();
    } else {
      appProvider.themeMode = ActiveThemeMode.dark;
      darkModeController.reverse();
    }
  }

  /// Theme toggle shared by the desktop sidebar and the tablet rail.
  Widget _buildDarkModeButton() {
    return ItemBuilder.buildDynamicToolButton(
      context: context,
      iconBuilder: (colors) => darkModeWidget ?? emptyWidget,
      onTap: changeMode,
      onChangemode: (context, themeMode, child) {
        if (darkModeController.duration != null) {
          if (themeMode == ActiveThemeMode.light) {
            darkModeController.forward();
          } else if (themeMode == ActiveThemeMode.dark) {
            darkModeController.reverse();
          } else {
            if (ColorUtil.isDark(context)) {
              darkModeController.reverse();
            } else {
              darkModeController.forward();
            }
          }
        }
      },
    );
  }

  _sideBar({
    double leftPadding = 0,
    double rightPadding = 0,
  }) {
    return Container(
      width: 42 + leftPadding + rightPadding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.only(left: leftPadding, right: rightPadding),
      child: Stack(
        children: [
          ResponsiveUtil.selectByPlatform(desktop: const WindowMoveHandle()),
          Consumer<LoftifyControlProvider>(
            builder: (_, cloudControlProvider, __) =>
                Selector<AppProvider, SideBarChoice>(
              selector: (context, appProvider) => appProvider.sidebarChoice,
              builder: (context, sidebarChoice, child) =>
                  Selector<AppProvider, bool>(
                selector: (context, appProvider) =>
                    !appProvider.showPanelNavigator,
                builder: (context, hideNavigator, child) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ResponsiveUtil.selectByPlatform(
                        desktop: const SizedBox(height: 5)),
                    ResponsiveUtil.selectByPlatform(desktop: _buildLogo()),
                    const SizedBox(height: 8),
                    ToolButton(
                      context: context,
                      selected:
                          hideNavigator && sidebarChoice == SideBarChoice.Home,
                      icon: LoftifyIcons.home,
                      selectedIcon: LoftifyIcons.home,
                      onPressed: () async {
                        appProvider.sidebarChoice = SideBarChoice.Home;
                        panelScreenState?.popAll(false);
                      },
                      iconSize: 24,
                    ),
                    const SizedBox(height: 8),
                    ToolButton(
                      context: context,
                      selected: hideNavigator &&
                          sidebarChoice == SideBarChoice.Search,
                      icon: LoftifyIcons.search,
                      selectedIcon: LoftifyIcons.search,
                      onPressed: () async {
                        appProvider.sidebarChoice = SideBarChoice.Search;
                        panelScreenState?.popAll(false);
                      },
                    ),
                    const SizedBox(height: 8),
                    Selector<AppProvider, bool>(
                      selector: (_, provider) => provider.ao3Enabled,
                      builder: (context, ao3Enabled, __) => ao3Enabled
                          ? ToolButton(
                              context: context,
                              selected: hideNavigator &&
                                  sidebarChoice == SideBarChoice.Ao3,
                              icon: Ao3Nav.iconFor(SideBarChoice.Ao3),
                              selectedIcon:
                                  Ao3Nav.iconFor(SideBarChoice.Ao3),
                              onPressed: () async {
                                appProvider.sidebarChoice =
                                    SideBarChoice.Ao3;
                                panelScreenState?.popAll(false);
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 8),
                    ToolButton(
                      context: context,
                      selected: hideNavigator &&
                          sidebarChoice == SideBarChoice.Dynamic,
                      icon: LoftifyIcons.activity,
                      selectedIcon: LoftifyIcons.activity,
                      onPressed: () async {
                        appProvider.sidebarChoice = SideBarChoice.Dynamic;
                        panelScreenState?.popAll(false);
                      },
                    ),
                    const SizedBox(height: 8),
                    ToolButton(
                      context: context,
                      selected:
                          hideNavigator && sidebarChoice == SideBarChoice.Mine,
                      icon: LoftifyIcons.profile,
                      selectedIcon: LoftifyIcons.profile,
                      onPressed: () async {
                        appProvider.sidebarChoice = SideBarChoice.Mine;
                        panelScreenState?.popAll(false);
                      },
                    ),
                    const Spacer(),
                    const SizedBox(height: 8),
                    ClickableGestureDetector(
                      onTap: () async {
                        if (blogInfo == null) {
                          RouteUtil.pushDialogRoute(
                              context, const LoginByCaptchaScreen());
                        } else {
                          BottomSheetBuilder.showContextMenu(
                              context, _buildAvatarContextMenuButtons());
                        }
                      },
                      child: ItemBuilder.buildAvatar(
                        showLoading: false,
                        context: context,
                        imageUrl: blogInfo?.bigAvaImg ?? "",
                        useDefaultAvatar: blogInfo == null,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDarkModeButton(),
                    const SizedBox(height: 2),
                    if (cloudControlProvider.globalControl.showDress) ...[
                      ToolButton(
                        context: context,
                        icon: LoftifyIcons.dress,
                        onPressed: () {
                          RouteUtil.pushPanelCupertinoRoute(
                              context, const SuitScreen());
                        },
                      ),
                      const SizedBox(height: 2),
                    ],
                    ToolButton(
                      context: context,
                      icon: LoftifyIcons.notifications,
                      onPressed: () {
                        RouteUtil.pushPanelCupertinoRoute(
                            context, const SystemNoticeScreen());
                      },
                    ),
                    const SizedBox(height: 2),
                    ToolButton(
                      context: context,
                      icon: LoftifyIcons.settings,
                      onPressed: () {
                        RouteUtil.pushPanelCupertinoRoute(
                            context, const SettingScreen());
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _buildLogo({
    double size = 50,
  }) {
    return IgnorePointer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/logo-transparent.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  void cancleTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
  }

  void setTimer() {
    if (!_hasJumpedToPinVerify) {
      _timer = Timer(
        Duration(seconds: appProvider.autoLockSeconds),
        () {
          jumpToLock();
        },
      );
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!ResponsiveUtil.isMobile() || _orientationPolicyUpdateScheduled) {
      return;
    }
    _orientationPolicyUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _orientationPolicyUpdateScheduled = false;
      if (mounted) {
        unawaited(ResponsiveUtil.checkSizeCondition());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        fetchData();
        cancleTimer();
        _scheduleClipboardCheck();
        break;
      case AppLifecycleState.paused:
        setTimer();
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    _clipboardTimer?.cancel();
    _clipboardLinks.dispose();
    trayManager.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    windowManager.removeListener(this);
    darkModeController.dispose();
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() {
    ChewieUtils.displayApp();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {}

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    Utils.processTrayMenuItemClick(context, menuItem, false);
  }

  @override
  bool get wantKeepAlive => true;
}
