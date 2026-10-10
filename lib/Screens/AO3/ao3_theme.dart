import 'package:flutter/material.dart';

import '../../Theme/loftify_design_theme.dart';

/// AO3 brand: the site's signature dark red. Everything AO3-related derives
/// its accent tones from this seed so the pages read as AO3 rather than as
/// the host app's accent.
abstract final class Ao3Brand {
  static const Color seed = Color(0xFF990000);

  /// A Material You (tonal) scheme generated from the AO3 brand color.
  static ColorScheme scheme(Brightness brightness) =>
      ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
}

/// Wraps AO3 surfaces in the brand palette. Two layers are rebranded:
/// the Material color scheme (chips, selection, progress, ink) and the
/// product design tokens (accent buttons, tonal surfaces), because this app
/// paints most accents from its own token set rather than from the scheme.
class Ao3Theme extends StatelessWidget {
  const Ao3Theme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final scheme = Ao3Brand.scheme(base.brightness);
    final design = LoftifyDesignThemeData.of(context);
    final branded = design.copyWith(
      colors: design.colors.copyWith(
        accent: scheme.primary,
        accentForeground: scheme.onPrimary,
        accentContainer: scheme.primaryContainer,
      ),
    );
    return Theme(
      data: base.copyWith(
        colorScheme: scheme,
        progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
          color: scheme.primary,
          linearTrackColor: design.colors.surfaceMuted,
        ),
        extensions: [
          for (final extension in base.extensions.values)
            if (extension is LoftifyDesignThemeData) branded else extension,
        ],
      ),
      child: child,
    );
  }
}
