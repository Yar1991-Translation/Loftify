import 'dart:ui' show lerpDouble;

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// Responsive width classes used by the Loftify design system.
enum LoftifyWindowClass { compact, medium, expanded, large }

/// Semantic density roles. Density describes information rhythm rather than
/// shrinking accessibility targets.
enum LoftifyDensityRole {
  contentDense,
  contentComfortable,
  controlComfortable,
}

@immutable
class LoftifyColorTokens {
  const LoftifyColorTokens({
    required this.page,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.outline,
    required this.outlineStrong,
    required this.accent,
    required this.accentForeground,
    required this.onAccent,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.danger,
    required this.scrim,
  });

  final Color page;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceMuted;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color outline;
  final Color outlineStrong;
  final Color accent;
  final Color accentForeground;
  final Color onAccent;
  final Color accentContainer;
  final Color onAccentContainer;
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color danger;
  final Color scrim;

  LoftifyColorTokens copyWith({
    Color? page,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? outline,
    Color? outlineStrong,
    Color? accent,
    Color? accentForeground,
    Color? onAccent,
    Color? accentContainer,
    Color? onAccentContainer,
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? danger,
    Color? scrim,
  }) {
    return LoftifyColorTokens(
      page: page ?? this.page,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      outline: outline ?? this.outline,
      outlineStrong: outlineStrong ?? this.outlineStrong,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      onAccent: onAccent ?? this.onAccent,
      accentContainer: accentContainer ?? this.accentContainer,
      onAccentContainer: onAccentContainer ?? this.onAccentContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      danger: danger ?? this.danger,
      scrim: scrim ?? this.scrim,
    );
  }

  static LoftifyColorTokens lerp(
    LoftifyColorTokens a,
    LoftifyColorTokens b,
    double t,
  ) {
    return LoftifyColorTokens(
      page: Color.lerp(a.page, b.page, t)!,
      surface: Color.lerp(a.surface, b.surface, t)!,
      surfaceRaised: Color.lerp(a.surfaceRaised, b.surfaceRaised, t)!,
      surfaceMuted: Color.lerp(a.surfaceMuted, b.surfaceMuted, t)!,
      textPrimary: Color.lerp(a.textPrimary, b.textPrimary, t)!,
      textSecondary: Color.lerp(a.textSecondary, b.textSecondary, t)!,
      textMuted: Color.lerp(a.textMuted, b.textMuted, t)!,
      outline: Color.lerp(a.outline, b.outline, t)!,
      outlineStrong: Color.lerp(a.outlineStrong, b.outlineStrong, t)!,
      accent: Color.lerp(a.accent, b.accent, t)!,
      accentForeground: Color.lerp(a.accentForeground, b.accentForeground, t)!,
      onAccent: Color.lerp(a.onAccent, b.onAccent, t)!,
      accentContainer: Color.lerp(
        a.accentContainer,
        b.accentContainer,
        t,
      )!,
      onAccentContainer: Color.lerp(
        a.onAccentContainer,
        b.onAccentContainer,
        t,
      )!,
      success: Color.lerp(a.success, b.success, t)!,
      successContainer:
          Color.lerp(a.successContainer, b.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(a.onSuccessContainer, b.onSuccessContainer, t)!,
      warning: Color.lerp(a.warning, b.warning, t)!,
      warningContainer:
          Color.lerp(a.warningContainer, b.warningContainer, t)!,
      onWarningContainer:
          Color.lerp(a.onWarningContainer, b.onWarningContainer, t)!,
      danger: Color.lerp(a.danger, b.danger, t)!,
      scrim: Color.lerp(a.scrim, b.scrim, t)!,
    );
  }
}

@immutable
class LoftifyTypographyTokens {
  const LoftifyTypographyTokens({
    required this.display,
    required this.pageTitle,
    required this.sectionTitle,
    required this.cardTitle,
    required this.body,
    required this.readingBody,
    required this.metadata,
    required this.label,
  });

  final TextStyle display;
  final TextStyle pageTitle;
  final TextStyle sectionTitle;
  final TextStyle cardTitle;
  final TextStyle body;
  final TextStyle readingBody;
  final TextStyle metadata;
  final TextStyle label;

  LoftifyTypographyTokens copyWith({
    TextStyle? display,
    TextStyle? pageTitle,
    TextStyle? sectionTitle,
    TextStyle? cardTitle,
    TextStyle? body,
    TextStyle? readingBody,
    TextStyle? metadata,
    TextStyle? label,
  }) {
    return LoftifyTypographyTokens(
      display: display ?? this.display,
      pageTitle: pageTitle ?? this.pageTitle,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      cardTitle: cardTitle ?? this.cardTitle,
      body: body ?? this.body,
      readingBody: readingBody ?? this.readingBody,
      metadata: metadata ?? this.metadata,
      label: label ?? this.label,
    );
  }

  static LoftifyTypographyTokens lerp(
    LoftifyTypographyTokens a,
    LoftifyTypographyTokens b,
    double t,
  ) {
    return LoftifyTypographyTokens(
      display: TextStyle.lerp(a.display, b.display, t)!,
      pageTitle: TextStyle.lerp(a.pageTitle, b.pageTitle, t)!,
      sectionTitle: TextStyle.lerp(a.sectionTitle, b.sectionTitle, t)!,
      cardTitle: TextStyle.lerp(a.cardTitle, b.cardTitle, t)!,
      body: TextStyle.lerp(a.body, b.body, t)!,
      readingBody: TextStyle.lerp(a.readingBody, b.readingBody, t)!,
      metadata: TextStyle.lerp(a.metadata, b.metadata, t)!,
      label: TextStyle.lerp(a.label, b.label, t)!,
    );
  }
}

@immutable
class LoftifySpacingTokens {
  const LoftifySpacingTokens({
    this.xxs = 2,
    this.xs = 4,
    this.sm = 6,
    this.md = 8,
    this.lg = 12,
    this.xl = 16,
    this.xxl = 20,
    this.xxxl = 24,
    this.huge = 32,
    this.hero = 40,
    this.sectionTop = 10,
  });

  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;
  final double huge;
  final double hero;

  /// Product requirement: each Caption-style setting group starts 10 px
  /// below the preceding content. Kept semantic because it is intentionally
  /// outside the general spacing ladder.
  final double sectionTop;

  static LoftifySpacingTokens lerp(
    LoftifySpacingTokens a,
    LoftifySpacingTokens b,
    double t,
  ) {
    return LoftifySpacingTokens(
      xxs: lerpDouble(a.xxs, b.xxs, t)!,
      xs: lerpDouble(a.xs, b.xs, t)!,
      sm: lerpDouble(a.sm, b.sm, t)!,
      md: lerpDouble(a.md, b.md, t)!,
      lg: lerpDouble(a.lg, b.lg, t)!,
      xl: lerpDouble(a.xl, b.xl, t)!,
      xxl: lerpDouble(a.xxl, b.xxl, t)!,
      xxxl: lerpDouble(a.xxxl, b.xxxl, t)!,
      huge: lerpDouble(a.huge, b.huge, t)!,
      hero: lerpDouble(a.hero, b.hero, t)!,
      sectionTop: lerpDouble(a.sectionTop, b.sectionTop, t)!,
    );
  }
}

@immutable
class LoftifyRadiusTokens {
  const LoftifyRadiusTokens({
    this.small = 6,
    this.control = 10,
    this.menu = 4,
    this.input = 4,
    this.card = 12,
    this.fab = 16,
    this.panel = 28,
    this.dialog = 28,
    this.full = 999,
  });

  final double small;
  final double control;
  final double menu;
  final double input;
  final double card;
  final double fab;
  final double panel;
  final double dialog;
  final double full;

  static LoftifyRadiusTokens lerp(
    LoftifyRadiusTokens a,
    LoftifyRadiusTokens b,
    double t,
  ) {
    return LoftifyRadiusTokens(
      small: lerpDouble(a.small, b.small, t)!,
      control: lerpDouble(a.control, b.control, t)!,
      menu: lerpDouble(a.menu, b.menu, t)!,
      input: lerpDouble(a.input, b.input, t)!,
      card: lerpDouble(a.card, b.card, t)!,
      fab: lerpDouble(a.fab, b.fab, t)!,
      panel: lerpDouble(a.panel, b.panel, t)!,
      dialog: lerpDouble(a.dialog, b.dialog, t)!,
      full: lerpDouble(a.full, b.full, t)!,
    );
  }
}

@immutable
class LoftifyBorderTokens {
  const LoftifyBorderTokens({
    this.hairline = 0.6,
    this.regular = 1,
    this.focus = 2,
  });

  final double hairline;
  final double regular;
  final double focus;

  static LoftifyBorderTokens lerp(
    LoftifyBorderTokens a,
    LoftifyBorderTokens b,
    double t,
  ) {
    return LoftifyBorderTokens(
      hairline: lerpDouble(a.hairline, b.hairline, t)!,
      regular: lerpDouble(a.regular, b.regular, t)!,
      focus: lerpDouble(a.focus, b.focus, t)!,
    );
  }
}

@immutable
class LoftifyShadowTokens {
  const LoftifyShadowTokens({
    required this.floating,
    required this.overlay,
  });

  final List<BoxShadow> floating;
  final List<BoxShadow> overlay;

  static LoftifyShadowTokens lerp(
    LoftifyShadowTokens a,
    LoftifyShadowTokens b,
    double t,
  ) {
    return LoftifyShadowTokens(
      floating: BoxShadow.lerpList(a.floating, b.floating, t)!,
      overlay: BoxShadow.lerpList(a.overlay, b.overlay, t)!,
    );
  }
}

@immutable
class LoftifyIconStateTokens {
  const LoftifyIconStateTokens({
    this.small = 16,
    this.regular = 20,
    this.large = 24,
    this.minimumTapTarget = 48,
    this.disabledOpacity = 0.38,
    this.hoverOpacity = 0.08,
    this.focusOpacity = 0.10,
    this.pressedOpacity = 0.12,
    this.selectedContainerOpacity = 0.12,
  });

  final double small;
  final double regular;
  final double large;
  final double minimumTapTarget;
  final double disabledOpacity;
  final double hoverOpacity;
  final double focusOpacity;
  final double pressedOpacity;
  final double selectedContainerOpacity;

  static LoftifyIconStateTokens lerp(
    LoftifyIconStateTokens a,
    LoftifyIconStateTokens b,
    double t,
  ) {
    return LoftifyIconStateTokens(
      small: lerpDouble(a.small, b.small, t)!,
      regular: lerpDouble(a.regular, b.regular, t)!,
      large: lerpDouble(a.large, b.large, t)!,
      minimumTapTarget: lerpDouble(a.minimumTapTarget, b.minimumTapTarget, t)!,
      disabledOpacity: lerpDouble(a.disabledOpacity, b.disabledOpacity, t)!,
      hoverOpacity: lerpDouble(a.hoverOpacity, b.hoverOpacity, t)!,
      focusOpacity: lerpDouble(a.focusOpacity, b.focusOpacity, t)!,
      pressedOpacity: lerpDouble(a.pressedOpacity, b.pressedOpacity, t)!,
      selectedContainerOpacity: lerpDouble(
        a.selectedContainerOpacity,
        b.selectedContainerOpacity,
        t,
      )!,
    );
  }
}

@immutable
class LoftifyDensityTokens {
  const LoftifyDensityTokens({
    this.contentDenseMinHeight = 48,
    this.contentComfortableMinHeight = 56,
    this.controlComfortableMinHeight = 56,
    this.contentDenseVerticalPadding = 10,
    this.contentComfortableVerticalPadding = 12,
    this.controlComfortableVerticalPadding = 14,
  });

  final double contentDenseMinHeight;
  final double contentComfortableMinHeight;
  final double controlComfortableMinHeight;
  final double contentDenseVerticalPadding;
  final double contentComfortableVerticalPadding;
  final double controlComfortableVerticalPadding;

  double minimumHeight(LoftifyDensityRole role) => switch (role) {
        LoftifyDensityRole.contentDense => contentDenseMinHeight,
        LoftifyDensityRole.contentComfortable => contentComfortableMinHeight,
        LoftifyDensityRole.controlComfortable => controlComfortableMinHeight,
      };

  double verticalPadding(LoftifyDensityRole role) => switch (role) {
        LoftifyDensityRole.contentDense => contentDenseVerticalPadding,
        LoftifyDensityRole.contentComfortable =>
          contentComfortableVerticalPadding,
        LoftifyDensityRole.controlComfortable =>
          controlComfortableVerticalPadding,
      };

  static LoftifyDensityTokens lerp(
    LoftifyDensityTokens a,
    LoftifyDensityTokens b,
    double t,
  ) {
    return LoftifyDensityTokens(
      contentDenseMinHeight: lerpDouble(
        a.contentDenseMinHeight,
        b.contentDenseMinHeight,
        t,
      )!,
      contentComfortableMinHeight: lerpDouble(
        a.contentComfortableMinHeight,
        b.contentComfortableMinHeight,
        t,
      )!,
      controlComfortableMinHeight: lerpDouble(
        a.controlComfortableMinHeight,
        b.controlComfortableMinHeight,
        t,
      )!,
      contentDenseVerticalPadding: lerpDouble(
        a.contentDenseVerticalPadding,
        b.contentDenseVerticalPadding,
        t,
      )!,
      contentComfortableVerticalPadding: lerpDouble(
        a.contentComfortableVerticalPadding,
        b.contentComfortableVerticalPadding,
        t,
      )!,
      controlComfortableVerticalPadding: lerpDouble(
        a.controlComfortableVerticalPadding,
        b.controlComfortableVerticalPadding,
        t,
      )!,
    );
  }
}

@immutable
class LoftifyMotionTokens {
  const LoftifyMotionTokens({
    this.press = const Duration(milliseconds: 90),
    this.state = const Duration(milliseconds: 180),
    this.page = const Duration(milliseconds: 220),
    this.panel = const Duration(milliseconds: 300),
    this.content = const Duration(milliseconds: 280),
    this.enterCurve = Curves.easeOutCubic,
    this.exitCurve = Curves.easeInCubic,
    this.emphasizedCurve = const Cubic(0.2, 0.0, 0.0, 1.0),
    this.emphasizedDecelerateCurve = const Cubic(0.05, 0.7, 0.1, 1.0),
  });

  final Duration press;
  final Duration state;
  final Duration page;
  final Duration panel;
  final Duration content;
  final Curve enterCurve;
  final Curve exitCurve;

  /// M3 emphasized easing for large state and surface transitions.
  final Curve emphasizedCurve;

  /// M3 emphasized-decelerate easing for incoming surfaces.
  final Curve emphasizedDecelerateCurve;

  Duration effective(BuildContext context, Duration duration) {
    return MediaQuery.maybeOf(context)?.disableAnimations == true
        ? Duration.zero
        : duration;
  }

  static LoftifyMotionTokens lerp(
    LoftifyMotionTokens a,
    LoftifyMotionTokens b,
    double t,
  ) {
    Duration lerpDuration(Duration start, Duration end) => Duration(
          microseconds: lerpDouble(
            start.inMicroseconds.toDouble(),
            end.inMicroseconds.toDouble(),
            t,
          )!
              .round(),
        );
    return LoftifyMotionTokens(
      press: lerpDuration(a.press, b.press),
      state: lerpDuration(a.state, b.state),
      page: lerpDuration(a.page, b.page),
      panel: lerpDuration(a.panel, b.panel),
      content: lerpDuration(a.content, b.content),
      enterCurve: t < 0.5 ? a.enterCurve : b.enterCurve,
      exitCurve: t < 0.5 ? a.exitCurve : b.exitCurve,
      emphasizedCurve: t < 0.5 ? a.emphasizedCurve : b.emphasizedCurve,
      emphasizedDecelerateCurve: t < 0.5
          ? a.emphasizedDecelerateCurve
          : b.emphasizedDecelerateCurve,
    );
  }
}

@immutable
class LoftifyGridTokens {
  const LoftifyGridTokens({
    this.compactBreakpoint = 600,
    this.mediumBreakpoint = 840,
    this.expandedBreakpoint = 1200,
    this.compactPagePadding = 12,
    this.phonePagePadding = 16,
    this.widePagePadding = 24,
    this.compactGutter = 10,
    this.mediumGutter = 12,
    this.wideGutter = 16,
    this.minimumCardWidth = 168,
    this.maximumDenseCardExtent = 300,
    this.maximumContentWidth = 1440,
    this.maximumReadingWidth = 720,
  });

  final double compactBreakpoint;
  final double mediumBreakpoint;
  final double expandedBreakpoint;
  final double compactPagePadding;
  final double phonePagePadding;
  final double widePagePadding;
  final double compactGutter;
  final double mediumGutter;
  final double wideGutter;
  final double minimumCardWidth;
  final double maximumDenseCardExtent;
  final double maximumContentWidth;
  final double maximumReadingWidth;

  LoftifyWindowClass windowClassFor(double width) {
    if (width < compactBreakpoint) return LoftifyWindowClass.compact;
    if (width < mediumBreakpoint) return LoftifyWindowClass.medium;
    if (width < expandedBreakpoint) return LoftifyWindowClass.expanded;
    return LoftifyWindowClass.large;
  }

  double pagePaddingFor(double width) => switch (windowClassFor(width)) {
        LoftifyWindowClass.compact =>
          width < 360 ? compactPagePadding : phonePagePadding,
        LoftifyWindowClass.medium ||
        LoftifyWindowClass.expanded ||
        LoftifyWindowClass.large =>
          widePagePadding,
      };

  /// Denser edge rhythm for image-led waterfall feeds on phones. Reading
  /// surfaces and discovery pages keep [pagePaddingFor] for calmer line
  /// lengths, while the home feed gives artwork more of the viewport.
  double denseFeedPagePaddingFor(double width) =>
      switch (windowClassFor(width)) {
        LoftifyWindowClass.compact => width < 360 ? 8 : 10,
        LoftifyWindowClass.medium ||
        LoftifyWindowClass.expanded ||
        LoftifyWindowClass.large =>
          widePagePadding,
      };

  double gutterFor(double width) => switch (windowClassFor(width)) {
        LoftifyWindowClass.compact => compactGutter,
        LoftifyWindowClass.medium => mediumGutter,
        LoftifyWindowClass.expanded || LoftifyWindowClass.large => wideGutter,
      };

  int contentColumnCount(double width) {
    final available =
        width.clamp(0, maximumContentWidth) - pagePaddingFor(width) * 2;
    final columns =
        ((available + gutterFor(width)) / (minimumCardWidth + gutterFor(width)))
            .floor();
    return columns.clamp(1, 6);
  }

  static LoftifyGridTokens lerp(
    LoftifyGridTokens a,
    LoftifyGridTokens b,
    double t,
  ) {
    return LoftifyGridTokens(
      compactBreakpoint:
          lerpDouble(a.compactBreakpoint, b.compactBreakpoint, t)!,
      mediumBreakpoint: lerpDouble(a.mediumBreakpoint, b.mediumBreakpoint, t)!,
      expandedBreakpoint:
          lerpDouble(a.expandedBreakpoint, b.expandedBreakpoint, t)!,
      compactPagePadding:
          lerpDouble(a.compactPagePadding, b.compactPagePadding, t)!,
      phonePagePadding: lerpDouble(a.phonePagePadding, b.phonePagePadding, t)!,
      widePagePadding: lerpDouble(a.widePagePadding, b.widePagePadding, t)!,
      compactGutter: lerpDouble(a.compactGutter, b.compactGutter, t)!,
      mediumGutter: lerpDouble(a.mediumGutter, b.mediumGutter, t)!,
      wideGutter: lerpDouble(a.wideGutter, b.wideGutter, t)!,
      minimumCardWidth: lerpDouble(a.minimumCardWidth, b.minimumCardWidth, t)!,
      maximumDenseCardExtent: lerpDouble(
        a.maximumDenseCardExtent,
        b.maximumDenseCardExtent,
        t,
      )!,
      maximumContentWidth:
          lerpDouble(a.maximumContentWidth, b.maximumContentWidth, t)!,
      maximumReadingWidth:
          lerpDouble(a.maximumReadingWidth, b.maximumReadingWidth, t)!,
    );
  }
}

/// Product-level theme contract for the "Quiet Content Atelier" direction.
@immutable
class LoftifyDesignThemeData extends ThemeExtension<LoftifyDesignThemeData> {
  const LoftifyDesignThemeData({
    required this.colors,
    required this.typography,
    this.spacing = const LoftifySpacingTokens(),
    this.radii = const LoftifyRadiusTokens(),
    this.borders = const LoftifyBorderTokens(),
    required this.shadows,
    this.icons = const LoftifyIconStateTokens(),
    this.density = const LoftifyDensityTokens(),
    this.motion = const LoftifyMotionTokens(),
    this.grid = const LoftifyGridTokens(),
  });

  final LoftifyColorTokens colors;
  final LoftifyTypographyTokens typography;
  final LoftifySpacingTokens spacing;
  final LoftifyRadiusTokens radii;
  final LoftifyBorderTokens borders;
  final LoftifyShadowTokens shadows;
  final LoftifyIconStateTokens icons;
  final LoftifyDensityTokens density;
  final LoftifyMotionTokens motion;
  final LoftifyGridTokens grid;

  static LoftifyDesignThemeData of(BuildContext context) {
    final extension = Theme.of(context).extension<LoftifyDesignThemeData>();
    return extension ?? LoftifyTheme._fallbackDesign(Theme.of(context));
  }

  @override
  LoftifyDesignThemeData copyWith({
    LoftifyColorTokens? colors,
    LoftifyTypographyTokens? typography,
    LoftifySpacingTokens? spacing,
    LoftifyRadiusTokens? radii,
    LoftifyBorderTokens? borders,
    LoftifyShadowTokens? shadows,
    LoftifyIconStateTokens? icons,
    LoftifyDensityTokens? density,
    LoftifyMotionTokens? motion,
    LoftifyGridTokens? grid,
  }) {
    return LoftifyDesignThemeData(
      colors: colors ?? this.colors,
      typography: typography ?? this.typography,
      spacing: spacing ?? this.spacing,
      radii: radii ?? this.radii,
      borders: borders ?? this.borders,
      shadows: shadows ?? this.shadows,
      icons: icons ?? this.icons,
      density: density ?? this.density,
      motion: motion ?? this.motion,
      grid: grid ?? this.grid,
    );
  }

  @override
  LoftifyDesignThemeData lerp(
    covariant LoftifyDesignThemeData? other,
    double t,
  ) {
    if (other == null) return this;
    return LoftifyDesignThemeData(
      colors: LoftifyColorTokens.lerp(colors, other.colors, t),
      typography: LoftifyTypographyTokens.lerp(typography, other.typography, t),
      spacing: LoftifySpacingTokens.lerp(spacing, other.spacing, t),
      radii: LoftifyRadiusTokens.lerp(radii, other.radii, t),
      borders: LoftifyBorderTokens.lerp(borders, other.borders, t),
      shadows: LoftifyShadowTokens.lerp(shadows, other.shadows, t),
      icons: LoftifyIconStateTokens.lerp(icons, other.icons, t),
      density: LoftifyDensityTokens.lerp(density, other.density, t),
      motion: LoftifyMotionTokens.lerp(motion, other.motion, t),
      grid: LoftifyGridTokens.lerp(grid, other.grid, t),
    );
  }
}

/// Builds the app ThemeData and keeps legacy Chewie colors and custom accent
/// themes as the authoritative user preference source.
abstract final class LoftifyTheme {
  static Color readableForegroundColor(
    Color source, {
    required List<Color> backgrounds,
    required Brightness brightness,
    double minimumContrast = 4.5,
  }) {
    assert(backgrounds.isNotEmpty);
    assert(minimumContrast > 1);
    return _readableForegroundColor(
      source,
      backgrounds: backgrounds,
      isDark: brightness == Brightness.dark,
      minimumContrast: minimumContrast,
    );
  }

  static ThemeData build(ChewieThemeColorData source) {
    final base = source.toThemeData();
    final isDark = source.isDarkMode;
    var scheme = _seededScheme(source.primaryColor, isDark: isDark);
    final colors = _semanticColors(
      scheme: scheme,
      success: source.successColor,
      warning: source.warningColor,
      danger: source.errorColor,
      isDark: isDark,
    );
    final errorPalette = TonalPalette.fromHct(
      Hct.fromInt(colors.danger.toARGB32()),
    );
    scheme = scheme.copyWith(
      error: colors.danger,
      onError: ColorUtil.getContrastColor(colors.danger),
      errorContainer: Color(errorPalette.get(isDark ? 30 : 90)),
      onErrorContainer: Color(errorPalette.get(isDark ? 90 : 10)),
    );
    final typography = _typography(base, colors);
    final shadows = _shadows(isDark: isDark);
    final design = LoftifyDesignThemeData(
      colors: colors,
      typography: typography,
      shadows: shadows,
    );
    final radii = design.radii;
    final icons = design.icons;
    final fontFamily = base.textTheme.bodyMedium?.fontFamily;
    final textTheme = _materialTextTheme(scheme, fontFamily);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radii.input),
      borderSide: BorderSide(color: scheme.outline),
    );
    final onSurface = scheme.onSurface;
    final iconTheme =
        (base.extension<ChewieIconThemeData>() ?? ChewieIconThemeData.standard)
            .copyWith(
      smallSize: icons.small,
      regularSize: icons.regular,
      largeSize: icons.large,
      minimumTapTarget: icons.minimumTapTarget,
      cornerRadius: radii.control,
      disabledOpacity: icons.disabledOpacity,
      hoverOpacity: icons.hoverOpacity,
      focusOpacity: icons.focusOpacity,
      pressedOpacity: icons.pressedOpacity,
      selectedContainerOpacity: icons.selectedContainerOpacity,
    );
    final extensions = base.extensions.values
        .where(
          (extension) =>
              extension is! LoftifyDesignThemeData &&
              extension is! ChewieIconThemeData,
        )
        .toList(growable: true)
      ..add(iconTheme)
      ..add(design);

    // M3 state layers applied to legacy Inks: onSurface at 8% hover and 10%
    // focus/pressed. Component themes apply their own spec layers on top.
    final stateLayerHover = onSurface.withValues(alpha: 0.08);
    final stateLayerFocus = onSurface.withValues(alpha: 0.10);
    final stateLayerPressed = onSurface.withValues(alpha: 0.10);

    return base.copyWith(
      colorScheme: scheme,
      primaryColor: scheme.primary,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      // Legacy content controls read cardColor as an information surface above
      // the page; the M3 surface-container tier keeps them distinguishable.
      cardColor: scheme.surfaceContainerHigh,
      dividerColor: scheme.outlineVariant,
      shadowColor: scheme.shadow,
      hintColor: scheme.onSurfaceVariant,
      splashColor: stateLayerPressed,
      highlightColor: stateLayerPressed,
      hoverColor: stateLayerHover,
      focusColor: stateLayerFocus,
      disabledColor: onSurface.withValues(alpha: 0.38),
      textTheme: textTheme,
      iconTheme: IconThemeData(
        color: scheme.onSurfaceVariant,
        size: icons.large,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.36),
        selectionHandleColor: scheme.primary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 3,
        surfaceTintColor: scheme.surfaceTint,
        shadowColor: scheme.shadow,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        actionsIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        backgroundColor: scheme.surface,
        elevation: 0,
        selectedItemColor: scheme.onSurface,
        unselectedItemColor: scheme.onSurfaceVariant,
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        height: 80,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 6,
        focusElevation: 6,
        hoverElevation: 8,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.fab),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 40),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: onSurface.withValues(alpha: 0.38),
          textStyle: textTheme.labelLarge,
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 40),
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.labelLarge,
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, 40),
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
          shape: const StadiumBorder(),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 40),
          backgroundColor: scheme.surfaceContainerLow,
          foregroundColor: scheme.primary,
          elevation: 1,
          shadowColor: scheme.shadow,
          surfaceTintColor: scheme.surfaceTint,
          textStyle: textTheme.labelLarge,
          shape: const StadiumBorder(),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: scheme.onSurfaceVariant,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.transparent,
        selectedColor: scheme.secondaryContainer,
        disabledColor: onSurface.withValues(alpha: 0.12),
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge
            ?.copyWith(color: scheme.onSecondaryContainer),
        iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        checkmarkColor: scheme.onSecondaryContainer,
        side: BorderSide(color: scheme.outline),
        shape: const StadiumBorder(),
        elevation: 0,
        pressElevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: scheme.surfaceTint,
        elevation: 6,
        shadowColor: scheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.dialog),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: scheme.surfaceTint,
        modalBackgroundColor: scheme.surfaceContainerLow,
        modalBarrierColor: colors.scrim,
        elevation: 0,
        modalElevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radii.panel),
          ),
        ),
        showDragHandle: false,
        dragHandleColor: scheme.onSurfaceVariant,
        dragHandleSize: const Size(32, 4),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        closeIconColor: scheme.onInverseSurface,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.menu),
        ),
      ),
      // Reset the legacy control overrides from the chewie base theme so the
      // M3 spec shapes and state colors apply.
      switchTheme: const SwitchThemeData(),
      checkboxTheme: const CheckboxThemeData(),
      radioTheme: const RadioThemeData(),
      progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
        refreshBackgroundColor: scheme.surfaceContainerHigh,
        strokeCap: StrokeCap.round,
        year2023: false,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: scheme.surfaceTint,
        shadowColor: scheme.shadow,
        elevation: 3,
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.menu),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            scheme.surfaceContainerHigh,
          ),
          surfaceTintColor: WidgetStatePropertyAll(scheme.surfaceTint),
          shadowColor: WidgetStatePropertyAll(scheme.shadow),
          elevation: const WidgetStatePropertyAll(3),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radii.menu),
            ),
          ),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: textTheme.bodyLarge,
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            scheme.surfaceContainerHigh,
          ),
          elevation: const WidgetStatePropertyAll(3),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radii.menu),
            ),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(radii.menu),
        ),
        textStyle: textTheme.bodyMedium
            ?.copyWith(color: scheme.onInverseSurface),
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: textTheme.titleSmall,
        unselectedLabelStyle: textTheme.titleSmall,
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: scheme.outlineVariant,
        splashFactory: null,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: false,
        hintStyle: textTheme.bodyMedium
            ?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: textTheme.bodyLarge
            ?.copyWith(color: scheme.onSurfaceVariant),
        errorStyle: textTheme.bodySmall?.copyWith(color: colors.danger),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.danger),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.danger, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: scheme.surfaceTint,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.card),
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodyMedium
            ?.copyWith(color: scheme.onSurfaceVariant),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(
          scheme.surfaceContainerHigh,
        ),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        textStyle: WidgetStatePropertyAll(textTheme.bodyLarge),
        hintStyle: WidgetStatePropertyAll(
          textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        constraints: const BoxConstraints(minHeight: 56),
      ),
      searchViewTheme: SearchViewThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        elevation: 3,
        surfaceTintColor: scheme.surfaceTint,
        headerTextStyle: textTheme.bodyLarge,
        dividerColor: scheme.outlineVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.full),
        ),
      ),
      extensions: extensions,
    );
  }

  /// Builds a full M3 ColorScheme seeded from the user's accent color.
  ///
  /// [DynamicSchemeVariant.tonalSpot] supplies the correct M3 neutral and
  /// container roles tinted toward the accent hue, while the primary family
  /// is re-derived from a hue-and-chroma-preserving tonal palette so the
  /// exact color the user picked always leads the theme.
  static ColorScheme _seededScheme(
    Color accent, {
    required bool isDark,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: isDark ? Brightness.dark : Brightness.light,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );
    final primaryPalette = TonalPalette.fromHct(Hct.fromInt(accent.toARGB32()));
    final primary = Color(primaryPalette.get(isDark ? 80 : 40));
    final onPrimary = Color(primaryPalette.get(isDark ? 20 : 100));
    final primaryContainer = Color(primaryPalette.get(isDark ? 30 : 90));
    final onPrimaryContainer = Color(primaryPalette.get(isDark ? 90 : 10));
    return scheme.copyWith(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      surfaceTint: primary,
    );
  }

  static LoftifyColorTokens _semanticColors({
    required ColorScheme scheme,
    required Color success,
    required Color warning,
    required Color danger,
    required bool isDark,
  }) {
    final page = scheme.surface;
    final surface = scheme.surfaceContainerLow;
    final surfaceRaised = scheme.surfaceContainerHigh;
    final surfaceMuted = scheme.surfaceContainerHighest;
    final textPrimary = scheme.onSurface;
    final textSecondary = scheme.onSurfaceVariant;
    final textMuted = _readableForegroundColor(
      scheme.outline,
      backgrounds: [page, surface, surfaceRaised, surfaceMuted],
      isDark: isDark,
    );
    final accentForeground = _readableForegroundColor(
      scheme.primary,
      backgrounds: [page, surface, surfaceRaised, surfaceMuted],
      isDark: isDark,
    );
    final outlineStrong = _readableForegroundColor(
      scheme.outline,
      backgrounds: [page, surface, surfaceRaised, surfaceMuted],
      isDark: isDark,
      minimumContrast: 3,
    );
    final readableSuccess = _readableStatusColor(
      success,
      backgrounds: [page, surfaceRaised],
      isDark: isDark,
    );
    final readableWarning = _readableStatusColor(
      warning,
      backgrounds: [page, surfaceRaised],
      isDark: isDark,
    );
    final readableDanger = _readableStatusColor(
      danger,
      backgrounds: [page, surfaceRaised],
      isDark: isDark,
    );
    final successPalette = TonalPalette.fromHct(
      Hct.fromInt(readableSuccess.toARGB32()),
    );
    final warningPalette = TonalPalette.fromHct(
      Hct.fromInt(readableWarning.toARGB32()),
    );
    return LoftifyColorTokens(
      page: page,
      surface: surface,
      surfaceRaised: surfaceRaised,
      surfaceMuted: surfaceMuted,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textMuted: textMuted,
      outline: scheme.outlineVariant,
      outlineStrong: outlineStrong,
      accent: scheme.primary,
      accentForeground: accentForeground,
      onAccent: scheme.onPrimary,
      accentContainer: scheme.primaryContainer,
      onAccentContainer: scheme.onPrimaryContainer,
      success: readableSuccess,
      successContainer: Color(successPalette.get(isDark ? 30 : 90)),
      onSuccessContainer: Color(successPalette.get(isDark ? 90 : 10)),
      warning: readableWarning,
      warningContainer: Color(warningPalette.get(isDark ? 30 : 90)),
      onWarningContainer: Color(warningPalette.get(isDark ? 90 : 10)),
      danger: readableDanger,
      scrim: Colors.black.withAlpha(isDark ? 156 : 104),
    );
  }

  static LoftifyDesignThemeData _fallbackDesign(ThemeData base) {
    final isDark = base.brightness == Brightness.dark;
    final scheme = _seededScheme(base.colorScheme.primary, isDark: isDark);
    final colors = _semanticColors(
      scheme: scheme,
      success: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
      warning: isDark ? const Color(0xFFFFB74D) : const Color(0xFF9A6700),
      danger: base.colorScheme.error,
      isDark: isDark,
    );
    return LoftifyDesignThemeData(
      colors: colors,
      typography: _typography(base, colors),
      shadows: _shadows(isDark: isDark),
    );
  }

  static double _contrastRatio(Color foreground, Color background) {
    final foregroundLuminance = foreground.computeLuminance();
    final backgroundLuminance = background.computeLuminance();
    final lighter = foregroundLuminance > backgroundLuminance
        ? foregroundLuminance
        : backgroundLuminance;
    final darker = foregroundLuminance > backgroundLuminance
        ? backgroundLuminance
        : foregroundLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }

  static Color _readableStatusColor(
    Color source, {
    required List<Color> backgrounds,
    required bool isDark,
  }) {
    bool isReadable(Color candidate) {
      for (final background in backgrounds) {
        final tinted = Color.alphaBlend(
          candidate.withValues(alpha: 0.10),
          background,
        );
        if (_contrastRatio(candidate, background) < 4.5 ||
            _contrastRatio(candidate, tinted) < 4.5) {
          return false;
        }
      }
      return true;
    }

    if (isReadable(source)) return source;
    final target = isDark ? Colors.white : Colors.black;
    for (var step = 1; step <= 100; step++) {
      final candidate = Color.lerp(source, target, step / 100)!;
      if (isReadable(candidate)) return candidate;
    }
    return target;
  }

  static Color _readableForegroundColor(
    Color source, {
    required List<Color> backgrounds,
    required bool isDark,
    double minimumContrast = 4.5,
  }) {
    bool isReadable(Color candidate) => backgrounds.every(
          (background) =>
              _contrastRatio(candidate, background) >= minimumContrast,
        );
    if (isReadable(source)) return source;
    final target = isDark ? Colors.white : Colors.black;
    for (var step = 1; step <= 100; step++) {
      final candidate = Color.lerp(source, target, step / 100)!;
      if (isReadable(candidate)) return candidate;
    }
    return target;
  }

  static LoftifyTypographyTokens _typography(
    ThemeData base,
    LoftifyColorTokens colors,
  ) {
    TextStyle role({
      required double size,
      required double height,
      required FontWeight weight,
      required Color color,
      double letterSpacing = 0,
    }) {
      return TextStyle(
        inherit: true,
        fontFamily: base.textTheme.bodyMedium?.fontFamily,
        fontFamilyFallback: base.textTheme.bodyMedium?.fontFamilyFallback,
        fontSize: size,
        height: height,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        decoration: TextDecoration.none,
      );
    }

    return LoftifyTypographyTokens(
      display: role(
        size: 28,
        height: 1.25,
        weight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      pageTitle: role(
        size: 20,
        height: 1.30,
        weight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      sectionTitle: role(
        size: 16,
        height: 1.35,
        weight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      cardTitle: role(
        size: 15,
        height: 1.40,
        weight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      body: role(
        size: 15,
        height: 1.60,
        weight: FontWeight.w400,
        color: colors.textPrimary,
      ),
      readingBody: role(
        size: 17,
        height: 1.80,
        weight: FontWeight.w400,
        color: colors.textPrimary,
      ),
      metadata: role(
        size: 12,
        height: 1.45,
        weight: FontWeight.w400,
        color: colors.textSecondary,
        letterSpacing: 0.1,
      ),
      label: role(
        size: 13,
        height: 1.30,
        weight: FontWeight.w600,
        color: colors.textPrimary,
        letterSpacing: 0.1,
      ),
    );
  }

  static LoftifyShadowTokens _shadows({required bool isDark}) {
    if (isDark) {
      return const LoftifyShadowTokens(
        floating: <BoxShadow>[
          BoxShadow(
            color: Color(0x52000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
        overlay: <BoxShadow>[
          BoxShadow(
            color: Color(0x70000000),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      );
    }
    return const LoftifyShadowTokens(
      floating: <BoxShadow>[
        BoxShadow(
          color: Color(0x140D1F18),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
      overlay: <BoxShadow>[
        BoxShadow(
          color: Color(0x1F0D1F18),
          blurRadius: 32,
          offset: Offset(0, 12),
        ),
      ],
    );
  }

  /// Builds the Material role text theme from the M3 2021 type scale,
  /// recolored to the scheme and pinned to the app's (custom) font family.
  /// Content typography keeps using [LoftifyTypographyTokens] directly.
  static TextTheme _materialTextTheme(
    ColorScheme scheme,
    String? fontFamily,
  ) {
    final base = Typography.material2021(
      platform: TargetPlatform.android,
    ).black;
    TextStyle? recolor(TextStyle? style, Color color) =>
        style?.copyWith(color: color, fontFamily: fontFamily);

    return base.copyWith(
      displayLarge: recolor(base.displayLarge, scheme.onSurface),
      displayMedium: recolor(base.displayMedium, scheme.onSurface),
      displaySmall: recolor(base.displaySmall, scheme.onSurface),
      headlineLarge: recolor(base.headlineLarge, scheme.onSurface),
      headlineMedium: recolor(base.headlineMedium, scheme.onSurface),
      headlineSmall: recolor(base.headlineSmall, scheme.onSurface),
      titleLarge: recolor(base.titleLarge, scheme.onSurface),
      titleMedium: recolor(base.titleMedium, scheme.onSurface),
      titleSmall: recolor(base.titleSmall, scheme.onSurface),
      bodyLarge: recolor(base.bodyLarge, scheme.onSurface),
      bodyMedium: recolor(base.bodyMedium, scheme.onSurface),
      bodySmall: recolor(base.bodySmall, scheme.onSurfaceVariant),
      labelLarge: recolor(base.labelLarge, scheme.onSurface),
      labelMedium: recolor(base.labelMedium, scheme.onSurfaceVariant),
      labelSmall: recolor(base.labelSmall, scheme.onSurfaceVariant),
    );
  }
}

extension LoftifyThemeContext on BuildContext {
  LoftifyDesignThemeData get design => LoftifyDesignThemeData.of(this);

  LoftifyWindowClass get windowClass =>
      design.grid.windowClassFor(MediaQuery.sizeOf(this).width);

  double get pageHorizontalPadding =>
      design.grid.pagePaddingFor(MediaQuery.sizeOf(this).width);
}
