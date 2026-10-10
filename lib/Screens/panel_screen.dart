/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Screens/Login/login_by_captcha_screen.dart';
import 'package:loftify/Screens/Navigation/dynamic_screen.dart';
import 'package:loftify/Screens/Navigation/mine_screen.dart';
import 'package:provider/provider.dart';

import '../Utils/app_provider.dart';
import '../Utils/enums.dart';
import '../Utils/lottie_files.dart';
import '../Widgets/Navigation/loftify_glass_navigation_bar.dart';
import '../l10n/l10n.dart';
import '../Utils/ao3_nav.dart';
import 'AO3/ao3_home_screen.dart';
import 'AO3/ao3_theme.dart';
import 'Navigation/home_screen.dart';
import 'Navigation/search_screen.dart';

class PanelBackScope extends StatelessWidget {
  const PanelBackScope({
    super.key,
    required this.canRootPop,
    required this.onNestedPop,
    required this.child,
  });

  final bool canRootPop;
  final FutureOr<void> Function() onNestedPop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canRootPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onNestedPop();
      },
      child: child,
    );
  }
}

class PanelScreen extends StatefulWidget {
  const PanelScreen({
    super.key,
  });

  static const String routeName = "/panel";

  @override
  State<PanelScreen> createState() => PanelScreenState();
}

class PanelScreenState extends BasePanelScreenState<PanelScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        ScrollToHideMixin {
  PageController _pageController = PageController();
  final Map<SideBarChoice, Widget> _pages = {};
  final Map<SideBarChoice, GlobalKey> _keys = {};
  bool unlogin = false;
  int _currentIndex = 0;
  late AnimationController darkModeController;
  Widget? darkModeWidget;
  final ScrollToHideController _scrollToHideController =
      ScrollToHideController();

  GlobalKey<NavigatorState> panelNavigatorKey = GlobalKey<NavigatorState>();

  NavigatorState? get panelNavigatorState => panelNavigatorKey.currentState;

  @override
  bool canPopPanelPage() => panelNavigatorState?.canPop() ?? false;

  bool canRootPop = true;

  @override
  void initState() {
    super.initState();
    updateStatusBar();
    darkModeController = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initPage();
      darkModeWidget = LottieFiles.buildAnimation(
        LottieFiles.sunLight,
        size: 25,
        autoForward: !ColorUtil.isDark(context),
        controller: darkModeController,
      );
    });
  }

  void login() {
    popAll();
    initPage();
  }

  void logout() {
    popAll();
    initPage();
  }

  @override
  void popAll([bool initPage = true]) {
    while (panelNavigatorState?.canPop() ?? false) {
      panelNavigatorState?.pop();
    }
    canRootPop = !(panelNavigatorState?.canPop() ?? false);
    appProvider.showPanelNavigator = false;
    if (initPage) {
      _pageController =
          PageController(initialPage: appProvider.sidebarChoice.index);
    }
  }

  @override
  void pushPage(Widget page) {
    ResponsiveUtil.runByOrientation(
      landscape: () {
        appProvider.showPanelNavigator = true;
        panelNavigatorState?.push(RouteUtil.getFadeRoute(page));
        canRootPop = false;
        if (mounted) setState(() {});
      },
      portrait: () {
        appProvider.showPanelNavigator = true;
        RouteUtil.pushCupertinoRoute(panelNavigatorState!.context, page);
        canRootPop = false;
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void popPage() {
    if (panelNavigatorState?.canPop() ?? false) {
      panelNavigatorState?.pop();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!(panelNavigatorState?.canPop() ?? false)) {
          appProvider.showPanelNavigator = false;
        }
      });
    } else {
      appProvider.showPanelNavigator = false;
    }
    _pageController =
        PageController(initialPage: appProvider.sidebarChoice.index);
    canRootPop = !(panelNavigatorState?.canPop() ?? false);
    if (mounted) setState(() {});
  }

  @override
  void updateStatusBar() {
    final brightness = appProvider.getBrightness() ??
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final systemUiOverlayStyle =
        AppBarWrapper.systemUiOverlayStyleForBrightness(
      brightness,
      includeNavigationBar: true,
    );
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }

  /// One widget instance per tab, created lazily with a stable key so
  /// toggling the AO3 tab rebuilds the page list without losing tab state.
  Widget _pageFor(SideBarChoice choice) {
    return _pages.putIfAbsent(choice, () {
      switch (choice) {
        case SideBarChoice.Home:
          return HomeScreen(key: _keyFor(choice));
        case SideBarChoice.Search:
          return SearchScreen(key: _keyFor(choice));
        case SideBarChoice.Ao3:
          return Ao3HomeScreen(key: _keyFor(choice));
        case SideBarChoice.Dynamic:
          return DynamicScreen(key: _keyFor(choice));
        case SideBarChoice.Mine:
          return MineScreen(key: _keyFor(choice));
      }
    });
  }

  /// Every tab resolves its key here, and lookups (scroll controllers for the
  /// collapsing bar, bottom-bar taps) go through the same map. Home and search
  /// use the shared global keys the rest of the app reaches them by; missing
  /// them here silently broke the bar's scroll tracking on those two tabs.
  GlobalKey _keyFor(SideBarChoice choice) {
    switch (choice) {
      case SideBarChoice.Home:
        return homeScreenKey;
      case SideBarChoice.Search:
        return searchScreenKey;
      case SideBarChoice.Ao3:
      case SideBarChoice.Dynamic:
      case SideBarChoice.Mine:
        return _keys.putIfAbsent(choice, () => GlobalKey());
    }
  }

  /// The live state of a tab. Every lookup must go through [_keyFor]: the map
  /// only holds the tabs that build their own key, so indexing it directly
  /// leaves the home and search tabs without scroll controllers and the
  /// floating bar then never collapses on them.
  State? _stateOf(SideBarChoice choice) => _keyFor(choice).currentState;

  BottomNavgationMixin? _bottomNavigationOf(SideBarChoice choice) {
    final state = _stateOf(choice);
    if (state is BottomNavgationMixin) {
      return state as BottomNavgationMixin;
    }
    return null;
  }

  List<ScrollController> _scrollControllersOf(SideBarChoice choice) {
    final state = _stateOf(choice);
    if (state is ScrollToHideMixin) {
      return (state as ScrollToHideMixin).getScrollControllers();
    }
    return const [];
  }

  Future<void> initPage() async {
    try {
      ILogger.debug(
          "init panel page and jump to ${Ao3Nav.visibleIndex(appProvider.sidebarChoice)}");
    } catch (e, t) {
      ILogger.error("Failed to init panel page", e, t);
    }
    jumpToPage(Ao3Nav.visibleIndex(appProvider.sidebarChoice));
    // The tab states (and their scroll controllers) only exist after the
    // build this schedules mounts them. Rebuild once more so the floating
    // navigation bar attaches its scroll listeners to the real controllers —
    // without this, scrolling on the initial tab never collapses the bar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void jumpToPage(int index) {
    _scrollToHideController.show();
    if (_currentIndex == index) {
      _bottomNavigationOf(Ao3Nav.choiceAt(index))?.onTapBottomNavigation();
    } else {
      _currentIndex = index;
      if (_pageController.hasClients) {
        final duration = LoftifyGlassNavigationBar.pageTransitionDuration(
          MediaQuery.of(context),
        );
        if (duration == Duration.zero) {
          _pageController.jumpToPage(index);
        } else {
          unawaited(
            _pageController.animateToPage(
              index,
              duration: duration,
              curve: Curves.easeOutCubic,
            ),
          );
        }
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void refreshScrollControllers() {
    setState(() {});
  }

  @override
  void showBottomNavigationBar() {
    _scrollToHideController.show();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var scaffold = Stack(
      children: [
        MyScaffold(
          body: unlogin
              ? Stack(
                  children: [
                    Center(
                      child: RoundIconTextButton(
                        text: appLocalizations.goToLogin,
                        background: ChewieTheme.primaryColor,
                        onPressed: () {
                          RouteUtil.pushDialogRoute(
                            rootContext,
                            const LoginByCaptchaScreen(),
                            popAll: true,
                          );
                        },
                      ),
                    ),
                    ResponsiveUtil.selectByPlatform(
                        andCondition: unlogin,
                        desktop: const WindowMoveHandle()),
                  ],
                )
              : PageView(
                  // Pre-build adjacent tabs so the first switch to a tab does
                  // not build its whole list mid animateToPage transition.
                  allowImplicitScrolling: true,
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _pageController,
                  children: [
                    for (final choice in Ao3Nav.choices()) _pageFor(choice),
                  ],
                ),
          extendBody: true,
          // The glass bottom bar belongs to the phone shell only: desktop
          // shows the icon sidebar and tablets the NavigationRail, so
          // mounting it there would stack two navigations at once.
          bottomNavigationBar: unlogin ||
                  ResponsiveUtil.isLandscapeLayout() ||
                  ResponsiveUtil.isTabletLayout()
              ? null
              : _buildBottomNavigationBar(),
        ),
        Selector<AppProvider, bool>(
          selector: (context, provider) => provider.showPanelNavigator,
          builder: (context, value, child) => Offstage(
            offstage: !value,
            child: Navigator(
              key: panelNavigatorKey,
              onGenerateRoute: (settings) {
                return RouteUtil.getFadeRoute(
                  emptyWidget,
                  duration: Duration.zero,
                );
              },
            ),
          ),
        ),
      ],
    );
    return PanelBackScope(
      canRootPop: canRootPop,
      onNestedPop: popPage,
      child: scaffold,
    );
  }

  Widget _buildBottomNavigationBar() {
    if (!LoftifyGlassNavigationBar.shouldShowForKeyboard(
      MediaQuery.of(context),
    )) {
      return const SizedBox.shrink();
    }
    return Selector<
        AppProvider,
        ({
          bool reduceTransparency,
          NavigationBarDisplayStyle displayStyle,
          NavigationBarPlacement placement,
        })>(
      selector: (context, appProvider) => (
        reduceTransparency: appProvider.reduceTransparency,
        displayStyle: appProvider.navigationBarDisplayStyle,
        placement: appProvider.navigationBarPlacement,
      ),
      builder: (context, preferences, child) => LoftifyGlassNavigationBar(
        currentIndex: _currentIndex,
        enableBlur: !preferences.reduceTransparency,
        displayStyle: preferences.displayStyle,
        placement: preferences.placement,
        scrollControllers: getScrollControllers(),
        controller: _scrollToHideController,
        destinations: [
          for (final choice in Ao3Nav.choices())
            LoftifyNavigationDestination(
              icon: Ao3Nav.iconFor(choice),
              accentColor: choice == SideBarChoice.Ao3
                  ? Ao3Brand.scheme(Theme.of(context).brightness).primary
                  : null,
              lottieAsset: switch (choice) {
                SideBarChoice.Home => LottieFiles.navCompass,
                SideBarChoice.Search => LottieFiles.navSearch,
                SideBarChoice.Dynamic => LottieFiles.navHeart,
                _ => null,
              },
              label: switch (choice) {
                SideBarChoice.Home => appLocalizations.home,
                SideBarChoice.Search => appLocalizations.search,
                SideBarChoice.Ao3 => appLocalizations.ao3Home,
                SideBarChoice.Dynamic => appLocalizations.dynamicTab,
                SideBarChoice.Mine => appLocalizations.mine,
              },
            ),
        ],
        onSelect: (index) {
          appProvider.sidebarChoice = Ao3Nav.choiceAt(index);
        },
      ),
    );
  }

  void changeMode() {
    if (ColorUtil.isDark(context)) {
      appProvider.themeMode = ActiveThemeMode.light;
      darkModeController.forward();
    } else {
      appProvider.themeMode = ActiveThemeMode.dark;
      darkModeController.reverse();
    }
  }

  @override
  List<ScrollController> getScrollControllers() {
    if (_currentIndex < 0) return const [];
    return _scrollControllersOf(Ao3Nav.choiceAt(_currentIndex));
  }

  @override
  bool get wantKeepAlive => true;
}
