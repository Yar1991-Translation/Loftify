import 'package:awesome_chewie/awesome_chewie.dart' hide ScaffoldMessenger;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:local_notifier/local_notifier.dart';

class IToast {
  static FToast? show(
    String text, {
    Icon? icon,
    String? decription,
    int seconds = 2,
    ToastGravity gravity = ToastGravity.TOP,
  }) {
    final rootContext = chewieProvider.rootContext;
    final messenger = ScaffoldMessenger.maybeOf(rootContext);
    if (messenger == null) return null;
    // Material 3 feedback: one floating SnackBar replaces both the desktop
    // notification queue and the mobile overlay toast. Per the Material
    // guidelines the feedback surface lives at the bottom of the screen.
    messenger.clearSnackBars();
    final theme = Theme.of(rootContext);
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[icon, const SizedBox(width: 8)],
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text),
                  if (decription.nullOrEmpty == false)
                    Text(
                      decription!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onInverseSurface
                            .withValues(alpha: 0.8),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        duration: Duration(seconds: seconds),
        // Fixed, not floating: a floating SnackBar asserts "presented off
        // screen" whenever a screen's persistent footer leaves no room
        // (batch download at large text scales) and silently vanishes in
        // release builds there. Fixed always docks visibly above the
        // bottom chrome.
        behavior: SnackBarBehavior.fixed,
      ),
    );
    return null;
  }

  static FToast? showTop(
    String text, {
    Icon? icon,
    String? decription,
  }) {
    if (text.nullOrEmpty) return null;
    return show(
      text,
      icon: icon,
      decription: decription,
    );
  }

  static FToast? showBottom(
    String text, {
    Icon? icon,
  }) {
    return show(text, icon: icon, gravity: ToastGravity.BOTTOM);
  }

  static LocalNotification? showDesktopNotification(
    String title, {
    String? subTitle,
    String? body,
    List<String> actions = const [],
    Function()? onClick,
    Function(int)? onClickAction,
  }) {
    if (!ResponsiveUtil.isDesktop()) return null;
    var nActions =
        actions.map((e) => LocalNotificationAction(text: e)).toList();
    LocalNotification notification = LocalNotification(
      identifier: StringUtil.generateUid(),
      title: title,
      subtitle: subTitle,
      body: body,
      actions: nActions,
    );
    notification.onShow = () {};
    notification.onClose = (closeReason) {
      switch (closeReason) {
        case LocalNotificationCloseReason.userCanceled:
          break;
        case LocalNotificationCloseReason.timedOut:
          break;
        default:
      }
    };
    notification.onClick = onClick;
    notification.onClickAction = onClickAction;
    notification.show();
    return notification;
  }
}
