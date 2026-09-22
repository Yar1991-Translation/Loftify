import 'package:flutter/material.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class RouteUtil {
  static void pushRootPage(Widget page) {
    Navigator.of(chewieProvider.globalNavigatorContext)
        .pushAndRemoveUntil(RouteUtil.getFadeRoute(page), (_) => false);
  }

  static pushMaterialRoute(
    BuildContext context,
    Widget page, {
    Function(dynamic)? onThen,
    bool popAll = false,
  }) {
    final route = MaterialPageRoute(builder: (context) => page);
    final future = popAll
        ? Navigator.pushAndRemoveUntil(context, route, (_) => false)
        : Navigator.push(context, route);
    return future.then(onThen ?? (_) => {});
  }

  static pushCupertinoRoute(
    BuildContext context,
    Widget page, {
    Function(dynamic)? onThen,
    bool popAll = false,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ResponsiveUtil.isLandscapeLayout()) {
        pushFadeRoute(context, page, onThen: onThen);
      } else {
        if (popAll) {
          Navigator.pushAndRemoveUntil(
              context,
              CustomCupertinoPageRoute(builder: (context) => page),
              (_) => false).then(onThen ?? (_) => {});
        } else {
          Navigator.push(
                  context, CustomCupertinoPageRoute(builder: (context) => page))
              .then(onThen ?? (_) => {});
        }
      }
    });
  }

  static pushPanelCupertinoRoute(BuildContext context, Widget page) {
    final panelScreenState = chewieProvider.panelScreenState;
    if (panelScreenState != null) {
      return panelScreenState.pushPage(page);
    }
    return pushCupertinoRoute(context, page);
  }

  static getFadeRoute(
    Widget page, {
    Duration? duration,
    bool opaque = true,
  }) {
    // Desktop/landscape page entrance: quick emphasized fade with a subtle
    // settle scale so content "lands" instead of just cross-fading.
    return PageRouteBuilder(
      opaque: opaque,
      barrierColor: opaque ? null : Colors.transparent,
      transitionDuration: duration ?? const Duration(milliseconds: 250),
      reverseTransitionDuration: duration ?? const Duration(milliseconds: 200),
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation secondaryAnimation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.05, 0.7, 0.1, 1),
          reverseCurve: const Cubic(0.3, 0.0, 0.8, 0.15),
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
            // Isolate the page in its own layer so each animation frame only
            // re-blends the cached layer instead of re-rasterizing the whole
            // fullscreen subtree at partial opacity.
            child: RepaintBoundary(child: page),
          ),
        );
      },
    );
  }

  static pushFadeRoute(
    BuildContext context,
    Widget page, {
    Function(dynamic)? onThen,
    bool popAll = false,
    bool opaque = true,
  }) {
    final route = getFadeRoute(page, opaque: opaque);
    final future = popAll
        ? Navigator.pushAndRemoveUntil(context, route, (_) => false)
        : Navigator.push(context, route);
    return future.then(onThen ?? (_) => {});
  }

  static pushDialogRoute(
    BuildContext context,
    Widget page, {
    bool barrierDismissible = true,
    bool showClose = true,
    bool fullScreen = false,
    double? preferMinWidth,
    double? preferMinHeight,
    Function(dynamic)? onThen,
    bool useFade = false,
    bool popAll = false,
    bool animation = true,
    bool opaque = true,
  }) {
    if (ResponsiveUtil.isLandscapeLayout()) {
      if (DialogNavigatorHelper.isMounted()) {
        DialogNavigatorHelper.pushPage(page);
      } else {
        DialogBuilder.showPageDialog(
          context,
          child: page,
          barrierDismissible: barrierDismissible,
          showCloseButton: showClose,
          fullScreen: fullScreen,
          onThen: onThen,
          preferMinWidth: preferMinWidth,
          preferMinHeight: preferMinHeight,
          useAnimation: animation,
        );
      }
    } else {
      if (useFade) {
        pushFadeRoute(
          context,
          page,
          onThen: onThen,
          popAll: popAll,
          opaque: opaque,
        );
      } else {
        pushCupertinoRoute(context, page, onThen: onThen, popAll: popAll);
      }
    }
  }

  /// Pops the stack the current sub-page actually lives on. Desktop pushes
  /// sub-pages either onto the dialog navigator or the panel navigator; a
  /// blind pop of the root navigator here used to close whatever page sat
  /// underneath (or crash on an empty stack) when the dialog layer was not
  /// mounted.
  static void popSubPage(BuildContext context) {
    if (DialogNavigatorHelper.isMounted() && DialogNavigatorHelper.canPop()) {
      DialogNavigatorHelper.popPage();
      return;
    }
    final panelState = chewieProvider.panelScreenState;
    if (panelState != null && panelState.canPopPanelPage()) {
      panelState.popPage();
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}
