import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

/// A bordered floating tool button (refresh, scroll-to-top, ...).
///
/// Rewritten as a Material 3 [IconButton.outlined]: the previous version
/// stacked a 3D-tilt press animation and an InkWell fork over a blurred
/// box shadow per button. The border stays; the shadow and the tilt go.
class ShadowIconButton extends StatelessWidget {
  final dynamic icon;
  final Function()? onTap;
  final Function()? onLongPress;
  final double radius;
  final EdgeInsets? padding;

  const ShadowIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.onLongPress,
    this.radius = 8,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      onPressed: onTap,
      onLongPress: onLongPress,
      padding: padding ?? const EdgeInsets.all(10),
      style: IconButton.styleFrom(
        side: BorderSide(color: ChewieTheme.dividerColor, width: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius + 1),
        ),
      ),
      icon: icon ?? emptyWidget,
    );
  }
}
