import 'package:flutter/material.dart';

import 'package:awesome_chewie/awesome_chewie.dart';

class ExpandableItem extends StatefulWidget {
  final Widget summary;
  final Widget content;
  final bool initiallyExpanded;
  final Duration duration;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final Color? summaryBackground;
  final Color? contentBackground;
  final BorderRadius borderRadius;

  const ExpandableItem({
    super.key,
    required this.summary,
    required this.content,
    this.initiallyExpanded = false,
    this.duration = const Duration(milliseconds: 300),
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.padding = const EdgeInsets.all(12),
    this.summaryBackground,
    this.contentBackground,
    this.borderRadius = ChewieDimens.borderRadius8,
  });

  @override
  State<ExpandableItem> createState() => _ExpandableItemState();
}

class _ExpandableItemState extends State<ExpandableItem>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _arrowRotation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _arrowRotation = Tween<double>(begin: 0, end: 0.5).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: ChewieTheme.border,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: widget.borderRadius,
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                color: widget.summaryBackground ??
                    ChewieTheme.appBarBackgroundColor,
                borderRadius: _isExpanded
                    ? BorderRadius.vertical(
                        top: widget.borderRadius.topLeft,
                        bottom: Radius.zero,
                      )
                    : widget.borderRadius,
              ),
              child: Row(
                children: [
                  Expanded(child: widget.summary),
                  RotationTransition(
                    turns: _arrowRotation,
                    child: const Icon(ChewieIcons.expand),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: widget.duration,
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: _isExpanded
                ? Container(
                    key: const ValueKey(true),
                    width: double.infinity,
                    padding: widget.padding,
                    decoration: BoxDecoration(
                      color: widget.contentBackground ?? Colors.transparent,
                      borderRadius: BorderRadius.vertical(
                        bottom: widget.borderRadius.bottomLeft,
                      ),
                    ),
                    child: widget.content,
                  )
                : const SizedBox.shrink(key: ValueKey(false)),
          ),
        ],
      ),
    );
  }
}
