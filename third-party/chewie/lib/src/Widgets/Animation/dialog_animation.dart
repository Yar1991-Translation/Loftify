import 'package:flutter/material.dart';

class DialogAnimation extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final bool useAnimation;

  const DialogAnimation({
    super.key,
    required this.animation,
    required this.child,
    this.useAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    // M3 emphasized decelerate: a gentle settle-in without the old
    // easeOutBack overshoot, which read as bouncy on desktop surfaces.
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: const Cubic(0.05, 0.7, 0.1, 1),
      reverseCurve: const Cubic(0.3, 0.0, 0.8, 0.15),
    );

    return useAnimation
        ? ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curvedAnimation),
            child: FadeTransition(
              opacity: curvedAnimation,
              child: child,
            ),
          )
        : FadeTransition(
            opacity: animation,
            child: child,
          );
  }
}
