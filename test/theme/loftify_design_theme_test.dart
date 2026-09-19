import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/loftify_design_theme',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  /// Mirrors `_presetAccentColors` in select_theme_screen.dart.
  const presetAccentColors = <Color>[
    Color(0xFF14C2BB),
    Color(0xFF2196F3),
    Color(0xFF009688),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFFFF5722),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFFFF9800),
    Color(0xFF4CAF50),
    Color(0xFF3F51B5),
  ];

  double hctHue(Color color) => Hct.fromInt(color.toARGB32()).hue;
  double hctTone(Color color) => Hct.fromInt(color.toARGB32()).tone;

  group('LoftifyTheme', () {
    test('derives semantic surfaces from the M3 scheme', () {
      final light = LoftifyTheme.build(
        ChewieThemeColorData.defaultLightThemes.first,
      );
      final dark = LoftifyTheme.build(
        ChewieThemeColorData.defaultDarkThemes.first,
      );
      final lightDesign = light.extension<LoftifyDesignThemeData>()!;
      final darkDesign = dark.extension<LoftifyDesignThemeData>()!;
      final lightScheme = light.colorScheme;
      final darkScheme = dark.colorScheme;

      expect(lightDesign.colors.page, lightScheme.surface);
      expect(lightDesign.colors.surface, lightScheme.surfaceContainerLow);
      expect(
        lightDesign.colors.surfaceRaised,
        lightScheme.surfaceContainerHigh,
      );
      expect(lightDesign.colors.textPrimary, lightScheme.onSurface);
      expect(lightDesign.colors.textSecondary, lightScheme.onSurfaceVariant);
      expect(darkDesign.colors.page, darkScheme.surface);
      expect(darkDesign.colors.surface, darkScheme.surfaceContainerLow);

      // Dark tonal surfaces stay ordered by tone so elevation remains legible.
      expect(
        darkScheme.surface.computeLuminance(),
        lessThan(darkScheme.surfaceContainerLow.computeLuminance()),
      );
      expect(
        darkScheme.surfaceContainerLow.computeLuminance(),
        lessThan(darkScheme.surfaceContainerHigh.computeLuminance()),
      );
      expect(
        darkScheme.surfaceContainerHigh.computeLuminance(),
        lessThan(darkScheme.surfaceContainerHighest.computeLuminance()),
      );

      expect(light.scaffoldBackgroundColor, lightScheme.surface);
      expect(light.cardColor, lightScheme.surfaceContainerHigh);
      expect(light.appBarTheme.backgroundColor, lightScheme.surface);
      expect(light.appBarTheme.scrolledUnderElevation, 3);
      expect(light.appBarTheme.surfaceTintColor, lightScheme.surfaceTint);
      expect(lightScheme.surfaceTint, lightScheme.primary);
      expect(light.navigationBarTheme.backgroundColor,
          lightScheme.surfaceContainer);
    });

    test('keeps the seed hue leading the primary family', () {
      final sources = <ChewieThemeColorData>[
        ...ChewieThemeColorData.defaultLightThemes,
        ...ChewieThemeColorData.defaultDarkThemes,
        ...presetAccentColors.map(
          (accent) => ChewieThemeColorData.defaultLightThemes.first.copyWith(
            id: 'Custom-$accent',
            primaryColor: accent,
          ),
        ),
        ChewieThemeColorData.defaultLightThemes.first.copyWith(
          id: 'Custom-dark',
          primaryColor: const Color(0xFF00BCD4),
        ),
      ];
      for (final source in sources) {
        final theme = LoftifyTheme.build(source);
        final primary = theme.colorScheme.primary;
        final isDark = source.isDarkMode;
        final seedHct = Hct.fromInt(source.primaryColor.toARGB32());
        if (seedHct.chroma > 5) {
          // Hue is only meaningful above near-zero chroma; the SoftLight grey
          // accent intentionally skips this check.
          expect(
            hctHue(primary),
            closeTo(seedHct.hue, 2),
            reason: '${source.id} must keep the user-selected hue',
          );
        }
        expect(
          hctTone(primary),
          closeTo(isDark ? 80 : 40, 2),
          reason: '${source.id} primary must sit on the M3 tone ladder',
        );
        expect(
          _contrastRatio(theme.colorScheme.onPrimary, primary),
          greaterThanOrEqualTo(4.5),
          reason: '${source.id} onPrimary must stay readable',
        );
        expect(
          _contrastRatio(
            theme.colorScheme.onPrimaryContainer,
            theme.colorScheme.primaryContainer,
          ),
          greaterThanOrEqualTo(4.5),
          reason: '${source.id} primary container must stay readable',
        );
      }
    });

    test('defines the M3 geometry and content typography ladders', () {
      final design = LoftifyTheme.build(
        ChewieThemeColorData.defaultLightThemes.first,
      ).extension<LoftifyDesignThemeData>()!;

      expect(design.typography.pageTitle.fontSize, 20);
      expect(design.typography.body.fontSize, 15);
      expect(design.typography.body.height, 1.6);
      expect(design.typography.readingBody.fontSize, 17);
      expect(design.typography.readingBody.height, 1.8);
      expect(design.typography.pageTitle.decoration, TextDecoration.none);
      expect(
        <double>[
          design.spacing.xxs,
          design.spacing.xs,
          design.spacing.sm,
          design.spacing.md,
          design.spacing.lg,
          design.spacing.xl,
          design.spacing.xxl,
          design.spacing.xxxl,
          design.spacing.huge,
          design.spacing.hero,
        ],
        <double>[2, 4, 6, 8, 12, 16, 20, 24, 32, 40],
      );
      expect(design.radii.card, 12);
      expect(design.radii.panel, 28);
      expect(design.radii.dialog, 28);
      expect(design.radii.menu, 4);
      expect(design.radii.input, 4);
      expect(design.radii.fab, 16);
      expect(design.icons.minimumTapTarget, 48);
      expect(design.motion.press, const Duration(milliseconds: 90));
      expect(design.motion.panel, const Duration(milliseconds: 300));
    });

    test('Material roles use the M3 type scale', () {
      final theme = LoftifyTheme.build(
        ChewieThemeColorData.defaultLightThemes.first,
      );
      // The M3 sizes live in typography.geometryThemeFor(scriptCategory) and
      // are merged into the roles when Theme.of resolves; replicate that here.
      final textTheme = ThemeData.localize(
        theme,
        theme.typography.geometryThemeFor(ScriptCategory.englishLike),
      ).textTheme;
      expect(textTheme.titleLarge!.fontSize, 22);
      expect(textTheme.titleMedium!.fontSize, 16);
      expect(textTheme.titleSmall!.fontSize, 14);
      expect(textTheme.bodyLarge!.fontSize, 16);
      expect(textTheme.bodyMedium!.fontSize, 14);
      expect(textTheme.bodySmall!.fontSize, 12);
      expect(textTheme.labelLarge!.fontSize, 14);
    });

    test('supports copyWith and interpolates theme changes', () {
      final light = LoftifyTheme.build(
        ChewieThemeColorData.defaultLightThemes.first,
      ).extension<LoftifyDesignThemeData>()!;
      final dark = LoftifyTheme.build(
        ChewieThemeColorData.defaultDarkThemes.first,
      ).extension<LoftifyDesignThemeData>()!;
      final replaced = light.copyWith(
        colors: light.colors.copyWith(accent: Colors.purple),
      );
      final middle = light.lerp(dark, 0.5);

      expect(replaced.colors.accent, Colors.purple);
      expect(replaced.spacing.xl, light.spacing.xl);
      expect(
        middle.colors.page,
        Color.lerp(light.colors.page, dark.colors.page, 0.5),
      );
      expect(middle.radii.card, 12);
    });

    testWidgets('components can resolve a safe token fallback during reload', (
      tester,
    ) async {
      late LoftifyDesignThemeData resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              resolved = LoftifyDesignThemeData.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.colors.page.computeLuminance(), greaterThan(0.9));
      expect(resolved.icons.minimumTapTarget, 48);
      expect(tester.takeException(), isNull);
    });

    test('every semantic text level meets AA contrast on neutral surfaces', () {
      final failures = <String>[];
      for (final source in <ChewieThemeColorData>[
        ChewieThemeColorData.defaultLightThemes.first,
        ChewieThemeColorData.defaultDarkThemes.first,
      ]) {
        final colors = LoftifyTheme.build(
          source,
        ).extension<LoftifyDesignThemeData>()!.colors;
        for (final background in <Color>[
          colors.page,
          colors.surface,
          colors.surfaceRaised,
          colors.surfaceMuted,
        ]) {
          for (final foreground in <Color>[
            colors.textPrimary,
            colors.textSecondary,
            colors.textMuted,
          ]) {
            final ratio = _contrastRatio(foreground, background);
            if (ratio < 4.5) {
              failures.add(
                '${source.id}: $foreground on $background is '
                '${ratio.toStringAsFixed(3)}:1',
              );
            }
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('onPrimary meets AA contrast on every primary', () {
      for (final source in <ChewieThemeColorData>[
        ...ChewieThemeColorData.defaultLightThemes,
        ...ChewieThemeColorData.defaultDarkThemes,
      ]) {
        final scheme = LoftifyTheme.build(source).colorScheme;
        expect(
          _contrastRatio(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(4.5),
          reason: '${source.id} needs a readable foreground on its accent',
        );
      }
    });

    test('accent foreground meets AA contrast across accents', () {
      final sources = <ChewieThemeColorData>[
        ...ChewieThemeColorData.defaultLightThemes,
        ...ChewieThemeColorData.defaultDarkThemes,
        ...presetAccentColors.map(
          (accent) => ChewieThemeColorData.defaultLightThemes.first.copyWith(
            id: 'Custom-$accent',
            primaryColor: accent,
          ),
        ),
      ];
      final failures = <String>[];
      for (final source in sources) {
        final colors = LoftifyTheme.build(
          source,
        ).extension<LoftifyDesignThemeData>()!.colors;
        for (final background in <Color>[
          colors.page,
          colors.surface,
          colors.surfaceRaised,
          colors.surfaceMuted,
        ]) {
          final ratio = _contrastRatio(colors.accentForeground, background);
          if (ratio < 4.5) {
            failures.add(
              '${source.id}: ${colors.accentForeground} on $background is '
              '${ratio.toStringAsFixed(3)}:1',
            );
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('M3 component themes follow the spec shapes and roles', () {
      final theme = LoftifyTheme.build(
        ChewieThemeColorData.defaultLightThemes.first,
      );
      final scheme = theme.colorScheme;

      expect(
        theme.filledButtonTheme.style!.shape!.resolve({}),
        isA<StadiumBorder>(),
      );
      expect(
        theme.outlinedButtonTheme.style!.shape!.resolve({}),
        isA<StadiumBorder>(),
      );
      expect(
        theme.textButtonTheme.style!.shape!.resolve({}),
        isA<StadiumBorder>(),
      );
      expect(
        (theme.dialogTheme.shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(28),
      );
      expect(theme.dialogTheme.backgroundColor, scheme.surfaceContainerHigh);
      expect(
        theme.navigationBarTheme.height,
        80,
      );
      expect(
        theme.navigationBarTheme.indicatorColor,
        scheme.secondaryContainer,
      );
      expect(
        theme.snackBarTheme.backgroundColor,
        scheme.inverseSurface,
      );
      expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
      expect(theme.chipTheme.shape, isA<StadiumBorder>());
      expect(
        theme.floatingActionButtonTheme.backgroundColor,
        scheme.primaryContainer,
      );
      expect(
        (theme.floatingActionButtonTheme.shape! as RoundedRectangleBorder)
            .borderRadius,
        BorderRadius.circular(16),
      );
      expect(
        theme.textButtonTheme.style!.foregroundColor!.resolve({}),
        scheme.primary,
      );
      expect(
        (theme.inputDecorationTheme.focusedBorder! as OutlineInputBorder)
            .borderSide
            .color,
        scheme.primary,
      );
      expect(
        theme.bottomSheetTheme.backgroundColor,
        scheme.surfaceContainerLow,
      );
    });

    test('interactive outlines reach non-text contrast on every surface', () {
      final failures = <String>[];
      for (final source in <ChewieThemeColorData>[
        ...ChewieThemeColorData.defaultLightThemes,
        ...ChewieThemeColorData.defaultDarkThemes,
      ]) {
        final colors = LoftifyTheme.build(
          source,
        ).extension<LoftifyDesignThemeData>()!.colors;
        for (final background in <Color>[
          colors.page,
          colors.surface,
          colors.surfaceRaised,
          colors.surfaceMuted,
        ]) {
          final ratio = _contrastRatio(colors.outlineStrong, background);
          if (ratio < 3) {
            failures.add(
              '${source.id}: ${colors.outlineStrong} on $background is '
              '${ratio.toStringAsFixed(3)}:1',
            );
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('accent container content meets AA contrast in every theme', () {
      final sources = <ChewieThemeColorData>[
        ...ChewieThemeColorData.defaultLightThemes,
        ...ChewieThemeColorData.defaultDarkThemes,
        ...presetAccentColors.map(
          (accent) => ChewieThemeColorData.defaultLightThemes.first.copyWith(
            id: 'Custom-$accent',
            primaryColor: accent,
          ),
        ),
      ];
      for (final source in sources) {
        final colors = LoftifyTheme.build(
          source,
        ).extension<LoftifyDesignThemeData>()!.colors;
        expect(
          _contrastRatio(colors.onAccentContainer, colors.accentContainer),
          greaterThanOrEqualTo(4.5),
          reason: '${source.id} needs readable tonal content',
        );
      }
    });

    test('status colors keep their hues and gain readable containers', () {
      for (final source in <ChewieThemeColorData>[
        ...ChewieThemeColorData.defaultLightThemes,
        ...ChewieThemeColorData.defaultDarkThemes,
      ]) {
        final theme = LoftifyTheme.build(source);
        final colors = theme.extension<LoftifyDesignThemeData>()!.colors;
        expect(
          hctHue(colors.success),
          closeTo(hctHue(source.successColor), 2),
          reason: '${source.id} success hue must survive harmonization',
        );
        expect(
          hctHue(colors.warning),
          closeTo(hctHue(source.warningColor), 2),
          reason: '${source.id} warning hue must survive harmonization',
        );
        expect(
          hctHue(colors.danger),
          closeTo(hctHue(source.errorColor), 2),
          reason: '${source.id} danger hue must survive harmonization',
        );
        expect(colors.danger, isNot(colors.accent));
        expect(
          theme.colorScheme.error,
          colors.danger,
          reason: '${source.id} scheme error must carry the harmonized danger',
        );
        for (final pair in <(Color, Color)>[
          (colors.onSuccessContainer, colors.successContainer),
          (colors.onWarningContainer, colors.warningContainer),
        ]) {
          expect(
            _contrastRatio(pair.$1, pair.$2),
            greaterThanOrEqualTo(4.5),
            reason: '${source.id} status container must stay readable',
          );
        }
      }
    });

    test('semantic status colors remain readable on page and tinted surfaces',
        () {
      for (final source in <ChewieThemeColorData>[
        ...ChewieThemeColorData.defaultLightThemes,
        ...ChewieThemeColorData.defaultDarkThemes,
      ]) {
        final colors = LoftifyTheme.build(
          source,
        ).extension<LoftifyDesignThemeData>()!.colors;
        for (final status in <Color>[
          colors.success,
          colors.warning,
          colors.danger,
        ]) {
          final tintedPage = Color.alphaBlend(
            status.withValues(alpha: 0.10),
            colors.page,
          );
          final tintedRaised = Color.alphaBlend(
            status.withValues(alpha: 0.10),
            colors.surfaceRaised,
          );
          for (final background in <Color>[
            colors.page,
            colors.surfaceRaised,
            tintedPage,
            tintedRaised,
          ]) {
            expect(
              _contrastRatio(status, background),
              greaterThanOrEqualTo(4.5),
              reason: '${source.id} status color needs readable contrast',
            );
          }
        }
      }
    });
  });

  group('LoftifyGridTokens', () {
    const grid = LoftifyGridTokens();

    test('uses width rather than device labels for responsive classes', () {
      expect(grid.windowClassFor(599), LoftifyWindowClass.compact);
      expect(grid.windowClassFor(600), LoftifyWindowClass.medium);
      expect(grid.windowClassFor(840), LoftifyWindowClass.expanded);
      expect(grid.windowClassFor(1200), LoftifyWindowClass.large);
      expect(grid.pagePaddingFor(320), 12);
      expect(grid.pagePaddingFor(390), 16);
      expect(grid.pagePaddingFor(700), 24);
      expect(grid.denseFeedPagePaddingFor(320), 8);
      expect(grid.denseFeedPagePaddingFor(390), 10);
      expect(grid.denseFeedPagePaddingFor(700), 24);
    });

    test('keeps card grids bounded from narrow phone to large desktop', () {
      expect(grid.contentColumnCount(320), 1);
      expect(grid.contentColumnCount(390), 2);
      expect(grid.contentColumnCount(700), 3);
      expect(grid.contentColumnCount(2560), 6);
      expect(grid.maximumDenseCardExtent, 300);
      expect(grid.maximumReadingWidth, 720);
    });
  });
}

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground
      : background;
  final darker = identical(lighter, foreground) ? background : foreground;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
