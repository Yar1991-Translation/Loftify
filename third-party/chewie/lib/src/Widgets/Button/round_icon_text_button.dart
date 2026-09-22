import 'package:flutter/material.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class RoundIconTextButton extends StatelessWidget {
  final String? text;
  final String? tooltip;
  final Function()? onPressed;
  final Color? background;
  final Widget? icon;
  final EdgeInsets padding;
  final double radius;
  final Color? color;
  final double fontSizeDelta;
  final TextStyle? textStyle;
  final double? width;
  final double? height;
  final double? minHeight;
  final double spacing;
  final Border? border;
  final bool disabled;
  final Widget? trailing;

  const RoundIconTextButton({
    super.key,
    this.text,
    this.tooltip,
    Function()? onPressed,
    Function()? onTap,
    this.background,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.radius = 8,
    this.spacing = 4,
    this.color,
    this.fontSizeDelta = 0,
    this.textStyle,
    this.width,
    this.height = 48,
    this.minHeight = 32,
    this.border,
    this.disabled = false,
    this.trailing,
  }) : onPressed = onPressed ?? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isClickable = !disabled && onPressed != null;
    Color backgroundColor = background ?? ChewieTheme.cardColor;
    backgroundColor =
        disabled ? backgroundColor.withAlpha(127) : backgroundColor;
    Color textColor = color ??
        (background != null ? Colors.white : ChewieTheme.titleSmall.color!);
    textColor = disabled ? textColor.withAlpha(127) : textColor;
    // Material 3 FilledButton: the previous version stacked a 3D-tilt press
    // animation, an InkWell fork and a custom tooltip per button.
    final button = FilledButton(
      onPressed: isClickable ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        disabledBackgroundColor: backgroundColor,
        disabledForegroundColor: textColor,
        padding: padding,
        minimumSize: Size(width ?? 0, height ?? 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: border?.top ?? BorderSide.none,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) icon!,
          if (icon != null && text != null) SizedBox(width: spacing),
          Flexible(
            child: Text(
              text ?? "",
              style: textStyle ??
                  ChewieTheme.titleSmall.apply(
                    color: textColor,
                    fontWeightDelta: 2,
                    fontSizeDelta: fontSizeDelta,
                  ),
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: spacing),
            trailing!,
          ],
        ],
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
