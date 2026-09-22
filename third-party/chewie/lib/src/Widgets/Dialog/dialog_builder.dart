import 'package:flutter/material.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class DialogBuilder {
  /// Material 3 [AlertDialog] confirm dialog. The previous implementation
  /// routed through hand-styled dialog widgets with their own transition
  /// and margin machinery; the API (including the custom dialog coloring)
  /// is unchanged. Geometry parameters ([margin], [padding], [align],
  /// radii) are accepted for compatibility and resolved to the standard
  /// M3 dialog geometry.
  static showConfirmDialog(
    BuildContext context, {
    String? title,
    String? message,
    String? imagePath,
    TextAlign messageTextAlign = TextAlign.center,
    String? confirmButtonText,
    String? cancelButtonText,
    VoidCallback? onTapConfirm,
    VoidCallback? onTapCancel,
    CustomDialogType? customDialogType,
    Color? color,
    Color? textColor,
    Color? buttonTextColor,
    EdgeInsets? margin,
    EdgeInsets? padding,
    bool barrierDismissible = true,
    bool renderHtml = true,
    Alignment align = Alignment.bottomCenter,
    bool responsive = true,
  }) {
    final effectiveType = customDialogType ?? CustomDialogType.normal;
    return showDialog(
      context: chewieProvider.navigatorContextOf(context),
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => AlertDialog(
        title: title == null ? null : Text(title, textAlign: messageTextAlign),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imagePath != null) ...[
              Image.asset(imagePath),
              const SizedBox(height: 12),
            ],
            if (message.notNullOrEmpty)
              renderHtml
                  ? CustomHtmlWidget(
                      content: message!,
                      style: TextStyle(
                        color: textColor ?? ChewieTheme.bodySmall.color,
                        height: 1.5,
                        fontSize: 15,
                      ),
                    )
                  : Text(
                      message!,
                      textAlign: messageTextAlign,
                      style: TextStyle(
                        color: textColor ?? ChewieTheme.bodySmall.color,
                        height: 1.5,
                        fontSize: 15,
                      ),
                    ),
          ],
        ),
        actions: [
          // Material 3 dialog buttons: text button for the dismissive
          // action, tonal filled button for the confirming one.
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: ChewieTheme.errorColor,
            ),
            onPressed: () {
              onTapCancel?.call();
              Navigator.pop(dialogContext);
            },
            child: Text(cancelButtonText ?? chewieLocalizations.cancel),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: CustomDialogColors.getBgColor(
                dialogContext,
                effectiveType,
                color ?? ChewieTheme.primaryColor,
              ),
              foregroundColor: buttonTextColor ?? Colors.white,
            ),
            onPressed: () {
              onTapConfirm?.call();
              Navigator.pop(dialogContext);
            },
            child: Text(confirmButtonText ?? chewieLocalizations.confirm),
          ),
        ],
      ),
    );
  }

  /// Material 3 [AlertDialog] info dialog; see [showConfirmDialog] for the
  /// compatibility notes.
  static showInfoDialog(
    BuildContext context, {
    String? title,
    String? message,
    Widget? messageChild,
    String? imagePath,
    String? buttonText,
    VoidCallback? onTapDismiss,
    CustomDialogType? customDialogType,
    Color? color,
    Color? textColor,
    Color? buttonTextColor,
    EdgeInsets? margin,
    EdgeInsets? padding,
    bool barrierDismissible = true,
    bool renderHtml = true,
    Alignment align = Alignment.bottomCenter,
    bool responsive = true,
    bool topRadius = true,
    bool bottomRadius = true,
    bool forceNoMarginAtMobile = false,
  }) {
    final effectiveType = customDialogType ?? CustomDialogType.normal;
    return showDialog(
      context: chewieProvider.navigatorContextOf(context),
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => AlertDialog(
        title: title == null ? null : Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imagePath != null) ...[
              Image.asset(imagePath),
              const SizedBox(height: 12),
            ],
            if (message.notNullOrEmpty)
              renderHtml
                  ? CustomHtmlWidget(
                      content: message!,
                      style: TextStyle(
                        color: textColor ?? ChewieTheme.bodySmall.color,
                        height: 1.5,
                        fontSize: 15,
                      ),
                    )
                  : Text(
                      message!,
                      style: TextStyle(
                        color: textColor ?? ChewieTheme.bodySmall.color,
                        height: 1.5,
                        fontSize: 15,
                      ),
                    ),
            if (messageChild != null) messageChild,
          ],
        ),
        actions: [
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: CustomDialogColors.getBgColor(
                dialogContext,
                effectiveType,
                color ?? ChewieTheme.primaryColor,
              ),
              foregroundColor: buttonTextColor ?? Colors.white,
            ),
            onPressed: () {
              onTapDismiss?.call();
              Navigator.pop(dialogContext);
            },
            child: Text(buttonText ?? chewieLocalizations.confirm),
          ),
        ],
      ),
    );
  }

  static showPageDialog(
    BuildContext context, {
    required Widget child,
    bool barrierDismissible = true,
    bool showCloseButton = true,
    bool fullScreen = false,
    Function(dynamic)? onThen,
    double? preferMinWidth,
    double? preferMinHeight,
    bool useAnimation = true,
  }) {
    showGeneralDialog(
      barrierDismissible: barrierDismissible,
      context: chewieProvider.navigatorContextOf(context),
      barrierLabel: '',
      barrierColor: ChewieTheme.barrierColor,
      transitionDuration: ChewieTheme.animationDuration,
      transitionBuilder: (context, animation, secondaryAnimation, _) {
        return DialogAnimation(
          animation: animation,
          useAnimation: useAnimation,
          child: DialogWrapperWidget(
            showCloseButton: showCloseButton,
            fullScreen: fullScreen,
            preferMinWidth: preferMinWidth,
            preferMinHeight: preferMinHeight,
            barrierDismissible: barrierDismissible,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
    ).then(onThen ?? (_) => {});
  }
}
