import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../Theme/loftify_design_theme.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/enums.dart';
import '../Navigation/loftify_glass_navigation_bar.dart';
import '../loftify_icons.dart';

/// Phone-shell scroll-to-top affordance: a small round button (M3 small FAB
/// palette) that fades in once the list is more than a screen from the top
/// and fades back out near it.
class LoftifyScrollToTopButton extends StatefulWidget {
  const LoftifyScrollToTopButton({
    super.key,
    required this.scrollController,
    this.onTap,
  });

  /// Phone-shell docking: positions the button over a [Stack] so it clears
  /// the floating glass chrome. When the bar is docked to the bottom-right
  /// its collapsed button owns that corner, so the scroll-to-top button
  /// mirrors to the bottom-left instead of stacking above it.
  static Widget hosted({
    required BuildContext context,
    required ScrollController scrollController,
    VoidCallback? onTap,
  }) {
    final chromeAtRight =
        appProvider.navigationBarPlacement == NavigationBarPlacement.cornerDocked;
    // Clear the expanded pill (64 + 12 margin) and its soft shadow, not
    // just the collapsed button the clearance helper is sized for.
    final bottom = LoftifyGlassNavigationBar.contentClearance(context) + 24;
    return Positioned(
      left: chromeAtRight ? 16 : null,
      right: chromeAtRight ? null : 16,
      bottom: bottom,
      child: LoftifyScrollToTopButton(
        scrollController: scrollController,
        onTap: onTap,
      ),
    );
  }

  final ScrollController scrollController;

  /// Defaults to a smooth ride back to offset zero.
  final VoidCallback? onTap;

  @override
  State<LoftifyScrollToTopButton> createState() =>
      _LoftifyScrollToTopButtonState();
}

class _LoftifyScrollToTopButtonState extends State<LoftifyScrollToTopButton> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(covariant LoftifyScrollToTopButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_handleScroll);
      widget.scrollController.addListener(_handleScroll);
      // Rebind can swap in a controller at a very different offset
      // (e.g. tab switches); refresh visibility right away.
      _handleScroll();
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    if (!widget.scrollController.hasClients) {
      if (_visible && mounted) setState(() => _visible = false);
      return;
    }
    final position = widget.scrollController.position;
    // One full screen of context before the button earns its space.
    final shouldShow = position.pixels > position.viewportDimension;
    if (shouldShow != _visible && mounted) {
      setState(() => _visible = shouldShow);
    }
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }
    if (!widget.scrollController.hasClients) return;
    widget.scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    return IgnorePointer(
      ignoring: !_visible,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: design.motion.effective(context, design.motion.state),
        curve: design.motion.enterCurve,
        child: Material(
          color: design.colors.accentContainer,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _handleTap,
            child: SizedBox.square(
              dimension: design.icons.minimumTapTarget,
              child: Center(
                child: ChewieIcon(
                  LoftifyIcons.scrollTop,
                  size: 22,
                  color: design.colors.onAccentContainer,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
