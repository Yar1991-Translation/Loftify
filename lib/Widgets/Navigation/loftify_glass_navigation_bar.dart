import 'dart:async';
import 'dart:ui';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../Utils/enums.dart';
import '../../Utils/lottie_files.dart';
import '../../generated/app_localizations.dart';

@immutable
class LoftifyNavigationDestination {
  const LoftifyNavigationDestination({
    required this.icon,
    required this.label,
    this.lottieAsset,
    this.badgeCount = 0,
    this.accentColor,
  });

  final IconData icon;
  final String label;

  /// Optional per-destination brand color (AO3 red). When set it tints the
  /// icon, the label and the active indicator instead of the theme colors.
  final Color? accentColor;

  /// Retained for call-site compatibility; the Material 3 Expressive bar
  /// expresses selection through the shared icon component's fill axis
  /// instead of playing a Lottie per destination.
  final String? lottieAsset;
  final int badgeCount;
}

/// Material 3 Expressive floating bottom navigation bar.
///
/// A full-height (64dp) tonal pill that floats above the content with a
/// horizontal margin instead of docking edge-to-edge. The selected
/// destination expands into an active indicator that carries its label next
/// to a filled icon, while unselected destinations collapse to outline
/// icons only.
///
/// When the content scrolls down the whole pill morphs into a single
/// circular button showing the active destination's glyph; tapping that
/// button (or scrolling up) expands the bar again. Reduced motion drops the
/// morphs to instant state changes.
///
/// When the user has not opted into reduced transparency the pill renders as
/// a light frosted surface over `surfaceContainer`; with reduced
/// transparency (or reduced motion, high contrast, web) it falls back to
/// the opaque spec surface.
class LoftifyGlassNavigationBar extends StatefulWidget {
  const LoftifyGlassNavigationBar({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
    this.onDoubleTap,
    this.enableBlur = true,
    this.displayStyle = NavigationBarDisplayStyle.iconOnly,
    this.placement = NavigationBarPlacement.centered,
    this.scrollControllers = const [],
    this.controller,
  })  : assert(destinations.length >= 2),
        assert(currentIndex >= 0 && currentIndex < destinations.length);

  final List<LoftifyNavigationDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<int>? onDoubleTap;
  final bool enableBlur;
  final NavigationBarDisplayStyle displayStyle;

  /// Where the bar docks; the collapsed round button anchors at the same
  /// spot so the morph never repositions.
  final NavigationBarPlacement placement;

  /// Content scroll controllers whose reverse direction collapses the bar
  /// into a button and whose forward direction expands it again.
  final List<ScrollController> scrollControllers;

  /// Optional visibility controller; `show()` expands and `hide()` collapses
  /// the bar (wired to tab switches through [ScrollToHideController]).
  final ScrollToHideController? controller;

  static const double barHeight = 64;
  static const double indicatorHeight = 40;
  static const double blurSigma = 12;
  static const double pillRadius = 32;
  static const double collapsedButtonSize = 56;
  static const double itemMaxWidth = 140;

  /// Every destination keeps at least a 48 x 48 dp hit box even when the
  /// unselected indicator hugs a 22 dp icon (M3 minimum tap target).
  static const double itemMinTarget = 48;

  /// Height that scrolling content should leave free at its bottom so the
  /// floating chrome (collapsed round button is the tallest form) never
  /// covers the last row: button + 12 dp float margin + gesture inset.
  static double contentClearance(BuildContext context) {
    return collapsedButtonSize + 12 + MediaQuery.viewPaddingOf(context).bottom;
  }

  /// Same as [contentClearance], but zero outside the phone shell (desktop
  /// sidebar and tablet rail leave the bottom edge free).
  static double contentBottomPadding(BuildContext context) {
    if (ResponsiveUtil.isLandscapeLayout() || ResponsiveUtil.isTabletLayout()) {
      return 0;
    }
    return contentClearance(context);
  }
  static const Duration standardPageTransitionDuration = Duration(
    milliseconds: 220,
  );

  /// The collapse/expand morph runs on one clock: the size shell and the
  /// two cross-fading surfaces all derive from [morphDuration]/[morphCurve]
  /// (the surfaces via a single controller), so the change reads as one
  /// continuous motion instead of stacked animations with different curves.
  static const Duration morphDuration = Duration(milliseconds: 300);
  static const Curve morphCurve = Curves.easeInOutCubicEmphasized;

  /// Per-item motion (press, indicator pill, label expand) shares the
  /// curve family of the morph.
  static const Duration itemDuration = Duration(milliseconds: 260);
  static const Curve itemCurve = Curves.easeOutCubic;

  /// Scroll distance (px) that must accumulate in one direction before the
  /// bar flips state, so scroll jitter cannot retrigger the morph on every
  /// frame.
  static const double scrollFlipThreshold = 24;

  static bool shouldShowForKeyboard(MediaQueryData mediaQuery) {
    return mediaQuery.viewInsets.bottom <= 0;
  }

  static bool shouldReduceMotion(
    MediaQueryData mediaQuery, {
    bool? platformReduceMotion,
  }) {
    final reduceMotion = platformReduceMotion ??
        WidgetsBinding
            .instance.platformDispatcher.accessibilityFeatures.reduceMotion;
    return reduceMotion ||
        mediaQuery.disableAnimations ||
        mediaQuery.accessibleNavigation;
  }

  static Duration pageTransitionDuration(
    MediaQueryData mediaQuery, {
    bool? platformReduceMotion,
  }) {
    return shouldReduceMotion(
      mediaQuery,
      platformReduceMotion: platformReduceMotion,
    )
        ? Duration.zero
        : standardPageTransitionDuration;
  }

  static bool shouldUseBlur(
    MediaQueryData mediaQuery, {
    required bool enabled,
    bool isWeb = kIsWeb,
    bool? platformReduceMotion,
  }) {
    return enabled &&
        !isWeb &&
        !shouldReduceMotion(
          mediaQuery,
          platformReduceMotion: platformReduceMotion,
        ) &&
        !mediaQuery.highContrast;
  }

  @override
  State<LoftifyGlassNavigationBar> createState() =>
      _LoftifyGlassNavigationBarState();
}

class _LoftifyGlassNavigationBarState extends State<LoftifyGlassNavigationBar>
    with SingleTickerProviderStateMixin {
  final Map<ScrollController, VoidCallback> _scrollListeners = {};
  bool _collapsed = false;

  /// Measured pill width (content-sized outside the full-width dock), so the
  /// collapse clip can shrink from the real pill geometry on one clock.
  final GlobalKey _barSurfaceKey = GlobalKey();
  double? _pillWidth;

  /// Single clock for the whole morph: the shell size, the corner radius and
  /// both cross-fading surfaces derive from this controller, so no two
  /// implicit animations can land on different frames mid-morph.
  late final AnimationController _morph = AnimationController(
    vsync: this,
    duration: LoftifyGlassNavigationBar.morphDuration,
  );
  late final Animation<double> _barFade =
      Tween<double>(begin: 1, end: 0).animate(
    CurvedAnimation(
      parent: _morph,
      curve: const Interval(0, 0.6, curve: Curves.easeIn),
    ),
  );
  late final Animation<double> _buttonFade =
      Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(
      parent: _morph,
      // The button is fully solid before the shell settles, so the last
      // frame of the morph can never flash an empty shell.
      curve: const Interval(0.35, 0.9, curve: Curves.easeOut),
    ),
  );

  double _scrollPixels = 0;
  bool _scrollDownwards = false;
  double _scrollAccum = 0;

  @override
  void initState() {
    super.initState();
    _attachScrollControllers(widget.scrollControllers);
    widget.controller?.doShow = _expand;
    widget.controller?.doHide = _collapse;
  }

  @override
  void didUpdateWidget(covariant LoftifyGlassNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _attachScrollControllers(widget.scrollControllers);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller?.doShow == _expand) {
        oldWidget.controller?.doShow = null;
      }
      if (oldWidget.controller?.doHide == _collapse) {
        oldWidget.controller?.doHide = null;
      }
      widget.controller?.doShow = _expand;
      widget.controller?.doHide = _collapse;
    }
  }

  @override
  void dispose() {
    _morph.dispose();
    for (final entry in _scrollListeners.entries) {
      entry.key.removeListener(entry.value);
    }
    _scrollListeners.clear();
    if (widget.controller?.doShow == _expand) {
      widget.controller?.doShow = null;
    }
    if (widget.controller?.doHide == _collapse) {
      widget.controller?.doHide = null;
    }
    super.dispose();
  }

  void _attachScrollControllers(List<ScrollController> controllers) {
    final unique = controllers.toSet();
    for (final controller in _scrollListeners.keys.toList()) {
      if (!unique.contains(controller)) {
        controller.removeListener(_scrollListeners.remove(controller)!);
      }
    }
    for (final controller in unique) {
      if (_scrollListeners.containsKey(controller)) continue;
      void listener() => _handleScroll(controller);
      _scrollListeners[controller] = listener;
      controller.addListener(listener);
    }
  }

  void _handleScroll(ScrollController controller) {
    if (!controller.hasClients) return;
    final positions = controller.positions.toList(growable: false);
    if (positions.isEmpty) return;
    final position = positions.last;
    if (position.pixels <= position.minScrollExtent + 0.5) {
      _scrollAccum = 0;
      _expand();
      return;
    }
    final delta = position.pixels - _scrollPixels;
    _scrollPixels = position.pixels;
    if (delta == 0) return;
    final downwards = delta > 0;
    if (downwards != _scrollDownwards) {
      _scrollDownwards = downwards;
      _scrollAccum = 0;
    }
    _scrollAccum += delta.abs();
    if (_scrollAccum < LoftifyGlassNavigationBar.scrollFlipThreshold) {
      return;
    }
    _scrollAccum = 0;
    if (downwards) {
      _collapse();
    } else {
      _expand();
    }
  }

  void _expand() => _setCollapsed(false);

  void _collapse() => _setCollapsed(true);

  void _setCollapsed(bool value) {
    if (!mounted || _collapsed == value) return;
    final reduceMotion = LoftifyGlassNavigationBar.shouldReduceMotion(
      MediaQuery.of(context),
    );
    _morph.duration =
        reduceMotion ? Duration.zero : LoftifyGlassNavigationBar.morphDuration;
    setState(() => _collapsed = value);
    if (value) {
      _morph.forward();
    } else {
      _morph.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final useBlur = LoftifyGlassNavigationBar.shouldUseBlur(
      mediaQuery,
      enabled: widget.enableBlur,
    );
    final surfaceColor = useBlur
        ? scheme.surfaceContainer.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.9 : 0.86,
          )
        : scheme.surfaceContainer;
    final placement = widget.placement;
    final bottomInset = mediaQuery.viewPadding.bottom;

    final activeDestination = widget.destinations[widget.currentIndex];
    final surfaceDecoration = BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(
        LoftifyGlassNavigationBar.pillRadius,
      ),
      border: Border.all(color: scheme.outlineVariant, width: 0.6),
    );
    final expandedRadius = placement == NavigationBarPlacement.fullWidth
        ? const BorderRadius.vertical(top: Radius.circular(28))
        : BorderRadius.circular(LoftifyGlassNavigationBar.pillRadius);
    final elevationDecoration = BoxDecoration(
      borderRadius: expandedRadius,
      boxShadow: [
        BoxShadow(
          color: scheme.shadow.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.32 : 0.14,
          ),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );

    // Placement geometry: the pill docks per the user's choice and the
    // collapsed round button anchors at the same spot, so the morph is one
    // continuous motion without repositioning.
    final padding = switch (placement) {
      NavigationBarPlacement.fullWidth =>
        EdgeInsets.fromLTRB(0, 8, 0, bottomInset),
      _ => EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 12),
    };
    final anchor = switch (placement) {
      NavigationBarPlacement.cornerDocked => Alignment.bottomRight,
      _ => Alignment.bottomCenter,
    };

    // Capture the pill's natural width once layout settles; the collapse
    // geometry lerps from this value. Skipped mid-morph so a running
    // animation can never recompute its own start point.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _morph.isAnimating) return;
      final box =
          _barSurfaceKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final width = box.size.width;
      if (width <= 0) return;
      if (_pillWidth == null || (_pillWidth! - width).abs() > 0.5) {
        setState(() => _pillWidth = width);
      }
    });

    // Single-clock morph: one state flip drives the size shell, the
    // elevation container and the two cross-fading surfaces, all on the
    // same duration and curve. The bar surface keeps its natural size in an
    // UnconstrainedBox so the shrinking shell clips it instead of squeezing
    // its contents; the button fades in over the last part of the collapse
    // while the bar fades out over the first, so it reads as one motion.
    return Padding(
      padding: padding,
      // A fixed outer height keeps the scaffold from re-reserving space
      // while the bar morphs (extendBody scaffolds float it over content).
      child: SizedBox(
        height: LoftifyGlassNavigationBar.barHeight,
        child: Align(
          alignment: anchor,
          child: LayoutBuilder(
            builder: (context, constraints) => AnimatedBuilder(
              animation: _morph,
              child: Stack(
                alignment: anchor,
                clipBehavior: Clip.antiAlias,
                children: [
                  if (useBlur)
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: LoftifyGlassNavigationBar.blurSigma,
                          sigmaY: LoftifyGlassNavigationBar.blurSigma,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  FadeTransition(
                    opacity: _barFade,
                    child: IgnorePointer(
                      ignoring: _collapsed,
                      child: KeyedSubtree(
                        key: const ValueKey(
                          'loftify-m3e-navigation-bar',
                        ),
                        child: OverflowBox(
                          alignment: anchor,
                          fit: OverflowBoxFit.deferToChild,
                          minWidth: 0,
                          maxWidth: constraints.maxWidth,
                          minHeight: 0,
                          maxHeight: LoftifyGlassNavigationBar.barHeight,
                          child: KeyedSubtree(
                            key: _barSurfaceKey,
                            child: _buildBarSurface(
                              surfaceDecoration,
                              scheme,
                              fillWidth:
                                  placement == NavigationBarPlacement.fullWidth
                                      ? constraints.maxWidth
                                      : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  FadeTransition(
                    opacity: _buttonFade,
                    child: IgnorePointer(
                      ignoring: !_collapsed,
                      child: ExcludeSemantics(
                        excluding: !_collapsed,
                        child: SizedBox(
                          key: const ValueKey(
                            'loftify-m3e-navigation-collapse',
                          ),
                          width:
                              LoftifyGlassNavigationBar.collapsedButtonSize,
                          height:
                              LoftifyGlassNavigationBar.collapsedButtonSize,
                          child: _buildCollapseSurface(
                            surfaceDecoration,
                            activeDestination,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              builder: (context, child) {
                // One clock drives the whole morph: the clip shell shrinks
                // from the pill's real geometry to the round button while
                // the two surfaces cross-fade, so the pill visually melts
                // into the button instead of being cropped to it.
                final t =
                    LoftifyGlassNavigationBar.morphCurve.transform(_morph.value);
                final expandedWidth =
                    placement == NavigationBarPlacement.fullWidth
                        ? constraints.maxWidth
                        : _pillWidth;
                final width = expandedWidth == null
                    ? null
                    : lerpDouble(
                        expandedWidth,
                        LoftifyGlassNavigationBar.collapsedButtonSize,
                        t,
                      );
                final height = lerpDouble(
                  LoftifyGlassNavigationBar.barHeight,
                  LoftifyGlassNavigationBar.collapsedButtonSize,
                  t,
                )!;
                final radius = BorderRadius.lerp(
                  expandedRadius,
                  BorderRadius.circular(
                    LoftifyGlassNavigationBar.collapsedButtonSize / 2,
                  ),
                  t,
                )!;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    boxShadow: elevationDecoration.boxShadow,
                  ),
                  child: ClipRRect(
                    key: const ValueKey('loftify-m3e-navigation-morph-shell'),
                    borderRadius: radius,
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(width: width, height: height, child: child),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseSurface(
    BoxDecoration surfaceDecoration,
    LoftifyNavigationDestination activeDestination,
  ) {
    final scheme = Theme.of(context).colorScheme;
    // Standard context lookup (not the global getter): the bar is hosted in
    // widget tests whose harness has no Hive setup.
    final l10n = AppLocalizations.of(context);
    final expandLabel = l10n?.expandNavigationBar;
    return DecoratedBox(
      decoration: surfaceDecoration,
      child: Semantics(
        button: true,
        label: expandLabel == null
            ? activeDestination.label
            : '${activeDestination.label}, $expandLabel',
        excludeSemantics: true,
        onTap: _expand,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: _expand,
          child: Center(
            child: _NavigationIcon(
              icon: activeDestination.icon,
              selected: true,
              badgeCount: activeDestination.badgeCount,
              color: activeDestination.accentColor ??
                  scheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarSurface(
    BoxDecoration surfaceDecoration,
    ColorScheme scheme, {
    double? fillWidth,
  }) {
    final reduceMotion =
        LoftifyGlassNavigationBar.shouldReduceMotion(MediaQuery.of(context));
    final duration =
        reduceMotion ? Duration.zero : LoftifyGlassNavigationBar.itemDuration;
    final items = List.generate(widget.destinations.length, (index) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: _LoftifyNavigationItem(
          destination: widget.destinations[index],
          selected: widget.currentIndex == index,
          displayStyle: widget.displayStyle,
          duration: duration,
          onTap: () => widget.onSelect(index),
          onDoubleTap: widget.onDoubleTap == null
              ? null
              : () => widget.onDoubleTap!(index),
        ),
      );
    });
    return DecoratedBox(
      key: const ValueKey('loftify-m3e-navigation-surface'),
      decoration: surfaceDecoration,
      child: SizedBox(
        height: LoftifyGlassNavigationBar.barHeight,
        width: fillWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: fillWidth == null
              // Pill: hug the items. The 4 x 48 dp items fit any 320 dp
              // screen with their labels, so this FittedBox is only a
              // last-resort safety net (extreme text scales / tiny windows).
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: items,
                  ),
                )
              // Full-width dock: spread the destinations evenly.
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: items,
                ),
        ),
      ),
    );
  }
}

class _LoftifyNavigationItem extends StatefulWidget {
  const _LoftifyNavigationItem({
    required this.destination,
    required this.selected,
    required this.displayStyle,
    required this.duration,
    required this.onTap,
    this.onDoubleTap,
  });

  final LoftifyNavigationDestination destination;
  final bool selected;
  final NavigationBarDisplayStyle displayStyle;
  final Duration duration;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  @override
  State<_LoftifyNavigationItem> createState() => _LoftifyNavigationItemState();
}

class _LoftifyNavigationItemState extends State<_LoftifyNavigationItem> {
  bool _pressed = false;
  Timer? _doubleTapWindow;

  @override
  void dispose() {
    _doubleTapWindow?.cancel();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    widget.onTap();
    if (widget.onDoubleTap == null) return;
    if (_doubleTapWindow?.isActive == true) {
      _doubleTapWindow?.cancel();
      _doubleTapWindow = null;
      widget.onDoubleTap!();
      return;
    }
    _doubleTapWindow = Timer(
      const Duration(milliseconds: 300),
      () => _doubleTapWindow = null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = widget.selected;
    final displayStyle = widget.displayStyle;
    final showIcon = displayStyle != NavigationBarDisplayStyle.textOnly;
    // The M3E signature: the label expands inside the active pill. Text-only
    // style keeps every label visible without icons instead.
    final labelVisible =
        displayStyle == NavigationBarDisplayStyle.textOnly || selected;
    final accent = widget.destination.accentColor;
    final foreground = accent != null
        ? (selected ? accent : accent.withValues(alpha: 0.72))
        : (selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant);
    final semanticLabel = widget.destination.badgeCount > 0
        ? '${widget.destination.label}, ${widget.destination.badgeCount}'
        : widget.destination.label;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: _handleTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: LoftifyGlassNavigationBar.itemMinTarget,
            minHeight: LoftifyGlassNavigationBar.itemMinTarget,
          ),
          child: AnimatedScale(
          scale: _pressed ? 0.94 : 1,
          duration: widget.duration == Duration.zero
              ? Duration.zero
              : const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: LoftifyGlassNavigationBar.itemMaxWidth,
              ),
              child: AnimatedContainer(
                key: ValueKey(
                  'loftify-navigation-selection-${widget.destination.label}',
                ),
                duration: widget.duration,
                curve: Curves.easeOutCubic,
                height: LoftifyGlassNavigationBar.indicatorHeight,
                padding: EdgeInsets.symmetric(
                  horizontal: labelVisible ? 14 : 10,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? (accent?.withValues(alpha: 0.16) ??
                          scheme.secondaryContainer)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    LoftifyGlassNavigationBar.indicatorHeight / 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showIcon)
                      _NavigationIcon(
                        icon: widget.destination.icon,
                        selected: selected,
                        badgeCount: widget.destination.badgeCount,
                        color: foreground,
                      ),
                    Flexible(
                      child: AnimatedSize(
                        duration: widget.duration,
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.centerLeft,
                        child: labelVisible
                            ? Padding(
                                padding:
                                    EdgeInsets.only(left: showIcon ? 8 : 0),
                                child: MediaQuery.withClampedTextScaling(
                                  maxScaleFactor: 1.3,
                                  child: Text(
                                    widget.destination.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                      color: foreground,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class _NavigationIcon extends StatelessWidget {
  const _NavigationIcon({
    required this.icon,
    required this.selected,
    required this.badgeCount,
    required this.color,
  });

  final IconData icon;
  final bool selected;
  final int badgeCount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          ChewieIcon(
            icon,
            size: 22,
            color: color,
            fill: selected ? 1.0 : null,
          ),
          if (badgeCount > 0)
            Positioned(
              top: -4,
              right: -7,
              child: _NavigationBadge(count: badgeCount),
            ),
        ],
      ),
    );
  }
}

class _NavigationBadge extends StatelessWidget {
  const _NavigationBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count',
      child: Container(
        constraints: const BoxConstraints(minWidth: 15),
        height: 15,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.surface,
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          count > 99 ? '99+' : '$count',
          maxLines: 1,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onError,
            fontSize: 8,
            height: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Lottie-driven navigation glyph kept for standalone uses (tests, other
/// surfaces); the M3E bar itself uses the shared fill axis instead.
class LoftifyNavigationLottieIcon extends StatefulWidget {
  const LoftifyNavigationLottieIcon({
    super.key,
    required this.asset,
    required this.selected,
    required this.color,
    this.size = 22,
  });

  final String asset;
  final bool selected;
  final Color color;
  final double size;

  @override
  State<LoftifyNavigationLottieIcon> createState() =>
      _LoftifyNavigationLottieIconState();
}

class _LoftifyNavigationLottieIconState
    extends State<LoftifyNavigationLottieIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _loaded = false;
  bool _animateWhenLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..value = widget.selected ? 1 : 0;
  }

  @override
  void didUpdateWidget(covariant LoftifyNavigationLottieIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      _loaded = false;
      _animateWhenLoaded = widget.selected;
      _controller.value = widget.selected ? 1 : 0;
      return;
    }
    if (oldWidget.selected == widget.selected) return;
    if (!widget.selected) {
      _animateWhenLoaded = false;
      _controller.value = 0;
      return;
    }
    if (LoftifyGlassNavigationBar.shouldReduceMotion(MediaQuery.of(context))) {
      _controller.value = 1;
    } else if (_loaded) {
      _controller.forward(from: 0);
    } else {
      _animateWhenLoaded = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LottieFiles.buildAnimation(
      widget.asset,
      key: ValueKey(widget.asset),
      size: widget.size,
      controller: _controller,
      tint: widget.color,
      onLoaded: () {
        _loaded = true;
        if (!_animateWhenLoaded || !widget.selected) return;
        _animateWhenLoaded = false;
        if (LoftifyGlassNavigationBar.shouldReduceMotion(
          MediaQuery.of(context),
        )) {
          _controller.value = 1;
        } else {
          _controller.forward(from: 0);
        }
      },
    );
  }
}

/// Appended to phone-shell sliver lists so the last row clears the floating
/// glass chrome. Zero-height outside the phone shell, so hosts can add it
/// unconditionally.
class LoftifyNavClearanceSliver extends StatelessWidget {
  const LoftifyNavClearanceSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: LoftifyGlassNavigationBar.contentBottomPadding(context),
      ),
    );
  }
}
