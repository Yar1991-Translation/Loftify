
import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

class CustomConfirmDialogWidget extends StatefulWidget {
  final String? title;
  final String message;
  final String? imagePath;
  final String confirmButtonText;
  final String cancelButtonText;
  final VoidCallback onTapConfirm;
  final VoidCallback onTapCancel;
  final CustomDialogType customDialogType;
  final Color? color;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? buttonTextColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? radiusDimen;
  final TextAlign? messageTextAlign;
  final bool renderHtml;
  final Alignment align;

  const CustomConfirmDialogWidget({
    super.key,
    this.title,
    required this.message,
    required this.confirmButtonText,
    required this.cancelButtonText,
    required this.onTapConfirm,
    required this.onTapCancel,
    required this.customDialogType,
    this.color,
    this.backgroundColor,
    this.textColor = const Color(0xFF707070),
    this.buttonTextColor = Colors.white,
    this.imagePath,
    this.padding,
    this.margin,
    required this.renderHtml,
    this.radiusDimen,
    this.align = Alignment.bottomCenter,
    this.messageTextAlign = TextAlign.center,
  });

  @override
  State<CustomConfirmDialogWidget> createState() =>
      _CustomConfirmDialogWidgetState();
}

class _CustomConfirmDialogWidgetState
    extends BaseDynamicState<CustomConfirmDialogWidget> {
  @override
  Widget build(BuildContext context) {
    // Blur removed: the route's barrierColor scrim dims the content behind
    // the dialog (M3), without a full-screen filter pass.
    return SizedBox(
      child: Align(
        alignment: widget.align,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: ResponsiveUtil.isWideDevice()
                ? const BoxConstraints(maxWidth: 400)
                : null,
            margin: widget.margin ?? const EdgeInsets.all(16),
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            decoration: BoxDecoration(
              color:
                  widget.backgroundColor ??
                  Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(
                  widget.radiusDimen ?? 28),
              boxShadow: ChewieTheme.defaultBoxShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.title.notNullOrEmpty) ...[
                  Text(
                    widget.title!,
                    style: TextStyle(
                      fontSize: 19,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: widget.textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ],
                if (widget.message.notNullOrEmpty)
                  widget.renderHtml
                      ? CustomHtmlWidget(
                          content: widget.message,
                          style: TextStyle(
                            color:
                                widget.textColor ?? ChewieTheme.bodySmall.color,
                            height: 1.5,
                            fontSize: 15,
                          ),
                        )
                      : Text(
                          widget.message,
                          style: TextStyle(
                            color:
                                widget.textColor ?? ChewieTheme.bodySmall.color,
                            height: 1.5,
                            fontSize: 15,
                          ),
                          textAlign: widget.messageTextAlign,
                        ),
                const SizedBox(height: 16),
                // Material 3 dialog buttons: text button for the dismissive
                // action, tonal filled button for the confirming one.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: ChewieTheme.errorColor,
                        ),
                        onPressed: () {
                          widget.onTapCancel.call();
                          Navigator.pop(context);
                        },
                        child: Text(widget.cancelButtonText),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          backgroundColor: CustomDialogColors.getBgColor(
                            context,
                            widget.customDialogType,
                            widget.color ?? ChewieTheme.primaryColor,
                          ),
                          foregroundColor: widget.buttonTextColor ??
                              ChewieTheme.primaryButtonColor,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onTapConfirm.call();
                        },
                        child: Text(widget.confirmButtonText),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
