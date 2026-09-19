/// A Flutter package that provides a customizable shimmer loading effect with fading animation.
///
/// This package allows you to create skeleton loading screens similar to those used in
/// popular applications like Facebook, LinkedIn, etc. The shimmer effect alternates
/// between two colors with a smooth fade transition.
///
/// * author: quango
/// * email: quango2304@gmail.com
/// * github: https://github.com/quango2304/fade_shimmer

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Predefined themes for the shimmer effect.
///
/// [light] - Light theme with light gray colors suitable for light mode interfaces.
/// [dark] - Dark theme with dark gray colors suitable for dark mode interfaces.
enum FadeTheme { light, dark }

/// Shared phase clock for every visible [FadeShimmer].
///
/// One reference-counted ticker replaces the old always-running periodic
/// timer + per-instance `setState` broadcast: mounted skeletons listen to a
/// single [ValueNotifier], the ticker stops when the last skeleton unmounts,
/// and no skeleton ever calls `setState`.
class _FadeShimmerClock {
  _FadeShimmerClock._();

  static const int animationPeriodMs = 1000;

  static _FadeShimmerClock? _instance;
  static _FadeShimmerClock get instance => _instance ??= _FadeShimmerClock._();

  /// Completed half-cycles since the ticker started.
  final ValueNotifier<int> cycles = ValueNotifier(0);
  Ticker? _ticker;
  int _refs = 0;

  void acquire() {
    _refs++;
    _ticker ??= Ticker(_onTick);
    if (!_ticker!.isActive) _ticker!.start();
  }

  void release() {
    _refs = math.max(0, _refs - 1);
    if (_refs == 0) _ticker?.stop();
  }

  void _onTick(Duration elapsed) {
    final value = elapsed.inMilliseconds ~/ animationPeriodMs;
    if (cycles.value != value) cycles.value = value;
  }
}

/// A widget that displays a shimmer loading effect with fading animation.
///
/// The FadeShimmer widget creates a container that alternates between two colors
/// with a smooth fade transition, creating a shimmer loading effect. This is commonly
/// used for skeleton screens while content is loading.
///
/// Example usage:
/// ```dart
/// FadeShimmer(
///   width: 100,
///   height: 10,
///   radius: 4,
///   fadeTheme: FadeTheme.light,
/// )
/// ```
class FadeShimmer extends StatefulWidget {
  /// The highlight color of the shimmer effect.
  /// This is the brighter color that the shimmer transitions to.
  /// Must be provided if [fadeTheme] is null.
  final Color? highlightColor;

  /// The base color of the shimmer effect.
  /// This is the darker color that the shimmer starts with.
  /// Must be provided if [fadeTheme] is null.
  final Color? baseColor;

  /// The border radius of the shimmer container.
  /// Defaults to 0 (no rounded corners).
  final double radius;

  /// The width of the shimmer container.
  /// Required parameter.
  final double width;

  /// The height of the shimmer container.
  /// Required parameter.
  final double height;

  /// Predefined theme that sets both [highlightColor] and [baseColor].
  ///
  /// Use this for quick setup with either light or dark theme.
  /// If this is provided, [highlightColor] and [baseColor] are ignored.
  /// If this is null, both [highlightColor] and [baseColor] must be provided.
  final FadeTheme? fadeTheme;

  /// Delay time in milliseconds before the shimmer animation starts.
  ///
  /// Use this to create staggered animations where multiple shimmer elements
  /// animate with a slight delay between them, creating a wave-like effect.
  /// Defaults to 0 (no delay).
  final int millisecondsDelay;

  /// Global animation duration in milliseconds for all shimmer instances.
  ///
  /// Change this to make the animation faster or slower. Note that this setting
  /// affects all FadeShimmer widgets in the application.
  /// Defaults to 1000 milliseconds (1 second).
  static int animationDurationInMillisecond = 1000;

  /// Creates a FadeShimmer with the specified dimensions and appearance.
  ///
  /// Either [fadeTheme] or both [highlightColor] and [baseColor] must be provided.
  /// The [width] and [height] parameters are required to define the size of the shimmer.
  const FadeShimmer({
    super.key,
    this.millisecondsDelay = 0,
    this.radius = 0,
    this.fadeTheme,
    this.highlightColor,
    this.baseColor,
    required this.width,
    required this.height,
  }) : assert(
          (highlightColor != null && baseColor != null) || fadeTheme != null,
          'Either fadeTheme or both highlightColor and baseColor must be provided',
        );

  /// Creates a circular FadeShimmer with equal width and height.
  ///
  /// This is a convenience factory constructor for creating round shimmer effects,
  /// commonly used for profile picture or avatar placeholders.
  ///
  /// Example usage:
  /// ```dart
  /// FadeShimmer.round(
  ///   size: 48,
  ///   fadeTheme: FadeTheme.dark,
  /// )
  /// ```
  ///
  /// The [size] parameter defines both width and height, and the radius is set to
  /// half of the size to create a perfect circle.
  factory FadeShimmer.round({
    required double size,
    Color? highlightColor,
    int millisecondsDelay = 0,
    Color? baseColor,
    FadeTheme? fadeTheme,
  }) =>
      FadeShimmer(
        height: size,
        width: size,
        radius: size / 2,
        baseColor: baseColor,
        highlightColor: highlightColor,
        fadeTheme: fadeTheme,
        millisecondsDelay: millisecondsDelay,
      );

  @override
  State<FadeShimmer> createState() => _FadeShimmerState();
}

class _FadeShimmerState extends State<FadeShimmer> {
  _FadeShimmerClock get _clock => _FadeShimmerClock.instance;

  /// Returns the highlight color based on the provided [fadeTheme] or [widget.highlightColor].
  Color get highLightColor {
    final theme = widget.fadeTheme;
    if (theme != null) {
      switch (theme) {
        case FadeTheme.light:
          return const Color(0xffF9F9FB);
        case FadeTheme.dark:
          return const Color(0xff3A3E3F);
      }
    }
    return widget.highlightColor!;
  }

  /// Returns the base color based on the provided [fadeTheme] or [widget.baseColor].
  Color get baseColor {
    final theme = widget.fadeTheme;
    if (theme != null) {
      switch (theme) {
        case FadeTheme.light:
          return const Color(0xffE6E8EB);
        case FadeTheme.dark:
          return const Color(0xff2A2C2E);
      }
    }
    return widget.baseColor!;
  }

  @override
  void initState() {
    super.initState();
    _clock.acquire();
  }

  @override
  void dispose() {
    _clock.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final period = FadeShimmer.animationDurationInMillisecond;
    // Stagger is expressed in whole periods; per-millisecond offsets would
    // need a finer phase channel for no visible benefit on skeletons.
    final staggerPeriods =
        (widget.millisecondsDelay ~/ math.max(1, period)).clamp(0, 1);
    return ValueListenableBuilder<int>(
      valueListenable: _clock.cycles,
      builder: (context, cycles, _) {
        final highlighted = (cycles + staggerPeriods).isEven;
        return AnimatedContainer(
          curve: Curves.easeInOut,
          duration: Duration(milliseconds: period),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: highlighted ? highLightColor : baseColor,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}
