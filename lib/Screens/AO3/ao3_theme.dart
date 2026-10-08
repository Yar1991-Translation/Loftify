import 'package:flutter/material.dart';

/// AO3 brand: the site's signature dark red. Everything AO3-related derives
/// its accent tones from this seed so the pages read as AO3, not as the
/// host app's accent.
abstract final class Ao3Brand {
  static const Color seed = Color(0xFF990000);

  /// A Material You (tonal) scheme generated from the AO3 brand color, for
  /// the current brightness. Cheap to build; screens call it once per build.
  static ColorScheme scheme(Brightness brightness) =>
      ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
}

/// Wraps AO3 surfaces in the brand-derived color scheme. Widgets that read
/// the M3 scheme (chips, buttons, progress, selectors) pick up AO3 red
/// automatically; neutral surfaces and text stay on the app theme.
class Ao3Theme extends StatelessWidget {
  const Ao3Theme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Ao3Brand.scheme(Theme.of(context).brightness);
    return Theme(
      data: Theme.of(context).copyWith(colorScheme: scheme),
      child: child,
    );
  }
}
