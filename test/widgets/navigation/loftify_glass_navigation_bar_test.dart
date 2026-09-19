import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Widgets/Navigation/loftify_glass_navigation_bar.dart';
import 'package:loftify/Widgets/loftify_icons.dart';

const _destinations = <LoftifyNavigationDestination>[
  LoftifyNavigationDestination(
    icon: LoftifyIcons.home,
    label: 'Home',
  ),
  LoftifyNavigationDestination(
    icon: LoftifyIcons.search,
    label: 'Search',
  ),
  LoftifyNavigationDestination(
    icon: LoftifyIcons.activity,
    label: 'Activity',
    badgeCount: 120,
  ),
  LoftifyNavigationDestination(
    icon: LoftifyIcons.profile,
    label: 'Mine',
  ),
];

Widget _host({
  MediaQueryData mediaQuery = const MediaQueryData(size: Size(320, 640)),
  Brightness brightness = Brightness.light,
  bool enableBlur = true,
  int currentIndex = 0,
  ValueChanged<int>? onSelect,
  ValueChanged<int>? onDoubleTap,
  VoidCallback? onBodyTap,
  NavigationBarDisplayStyle displayStyle =
      NavigationBarDisplayStyle.iconAndText,
}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF14C2BB),
    brightness: brightness,
  );
  return MaterialApp(
    theme: ThemeData(colorScheme: colorScheme, brightness: brightness),
    home: MediaQuery(
      data: mediaQuery,
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onBodyTap,
          child: const ColoredBox(color: Color(0xFFB9DAD7)),
        ),
        bottomNavigationBar: LoftifyGlassNavigationBar(
          destinations: _destinations,
          currentIndex: currentIndex,
          enableBlur: enableBlur,
          displayStyle: displayStyle,
          onSelect: onSelect ?? (_) {},
          onDoubleTap: onDoubleTap,
        ),
      ),
    ),
  );
}

BoxDecoration _pillDecoration(WidgetTester tester, String label) {
  final container = tester.widget<AnimatedContainer>(
    find.byKey(ValueKey('loftify-navigation-selection-$label')),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  testWidgets('renders the M3E bar surface with a safe-area inset', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        enableBlur: false,
        mediaQuery: const MediaQueryData(
          size: Size(320, 640),
          viewPadding: EdgeInsets.only(bottom: 24),
        ),
      ),
    );

    final surface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('loftify-m3e-navigation-surface')),
    );
    final decoration = surface.decoration as BoxDecoration;
    final scheme = Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
    expect(decoration.color, scheme.surfaceContainer);
    expect(decoration.border, isNotNull);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(
      tester.getSize(find.byType(LoftifyGlassNavigationBar)).height,
      LoftifyGlassNavigationBar.barHeight + 24,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('translucent mode frosts the surface with a backdrop blur', (
    tester,
  ) async {
    await tester.pumpWidget(_host(enableBlur: true));

    expect(find.byType(BackdropFilter), findsOneWidget);
    final surface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('loftify-m3e-navigation-surface')),
    );
    final decoration = surface.decoration as BoxDecoration;
    expect(decoration.color!.a, lessThan(1.0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the selected destination expands a pill that carries its label',
      (tester) async {
    await tester.pumpWidget(_host(currentIndex: 0));
    await tester.pumpAndSettle();

    final scheme = Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
    expect(_pillDecoration(tester, 'Home').color, scheme.secondaryContainer);
    expect(_pillDecoration(tester, 'Search').color, Colors.transparent);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsNothing);
    expect(find.text('Mine'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text-only style keeps every label visible without icons', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        displayStyle: NavigationBarDisplayStyle.textOnly,
        currentIndex: 0,
      ),
    );
    await tester.pumpAndSettle();

    for (final label in ['Home', 'Search', 'Activity', 'Mine']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byType(ChewieIcon), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected destination uses the filled variant of its glyph', (
    tester,
  ) async {
    await tester.pumpWidget(_host(currentIndex: 2));
    await tester.pumpAndSettle();

    final icons = tester.widgetList<ChewieIcon>(find.byType(ChewieIcon));
    final filled = icons.where((icon) => icon.fill == 1.0);
    expect(filled, hasLength(1));
    expect(filled.single.icon, LoftifyIcons.activity);
    expect(icons.where((icon) => icon.fill == null), hasLength(3));
    expect(
      filled.single.color,
      Theme.of(tester.element(find.byType(Scaffold)))
          .colorScheme
          .onSecondaryContainer,
    );
  });

  testWidgets('dispatches tap and double-tap without material ripple', (
    tester,
  ) async {
    final selected = <int>[];
    var doubleTaps = 0;
    await tester.pumpWidget(
      _host(
        onSelect: selected.add,
        onDoubleTap: (_) => doubleTaps++,
      ),
    );

    await tester.tap(find.text('Home'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(selected, [0]);
    expect(find.byType(InkWell), findsNothing);
    expect(find.byType(InkRipple), findsNothing);

    await tester.tap(find.text('Home'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Home'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(doubleTaps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation consumes taps without activating content beneath', (
    tester,
  ) async {
    var bodyTaps = 0;
    await tester.pumpWidget(_host(onBodyTap: () => bodyTaps++));

    await tester.tap(find.text('Home'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(bodyTaps, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large badges stay on the icon and clamp to 99+', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.text('99+'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion applies selection state without animation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        mediaQuery: const MediaQueryData(
          size: Size(320, 640),
          disableAnimations: true,
        ),
      ),
    );
    await tester.pump();

    final container = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('loftify-navigation-selection-Home')),
    );
    expect(container.duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long labels stay bounded on narrow screens with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _host(
        mediaQuery: const MediaQueryData(
          size: Size(320, 640),
          textScaler: TextScaler.linear(2),
        ),
        currentIndex: 0,
      ),
    );
    await tester.pumpAndSettle();

    for (final label in ['Home', 'Search', 'Activity', 'Mine']) {
      final size = tester.getSize(
        find.byKey(ValueKey('loftify-navigation-selection-$label')),
      );
      expect(size.width, lessThanOrEqualTo(80));
    }
    expect(tester.takeException(), isNull);
  });

  test('motion helpers honor reduced-motion and keyboard state', () {
    const reduceMotion = MediaQueryData(
      size: Size(320, 640),
      disableAnimations: true,
    );
    const normal = MediaQueryData(size: Size(320, 640));
    expect(LoftifyGlassNavigationBar.shouldReduceMotion(reduceMotion), isTrue);
    expect(LoftifyGlassNavigationBar.shouldReduceMotion(normal), isFalse);
    expect(
      LoftifyGlassNavigationBar.pageTransitionDuration(reduceMotion),
      Duration.zero,
    );
    expect(
      LoftifyGlassNavigationBar.pageTransitionDuration(normal),
      LoftifyGlassNavigationBar.standardPageTransitionDuration,
    );
    expect(
      LoftifyGlassNavigationBar.shouldShowForKeyboard(
        const MediaQueryData(
          size: Size(320, 640),
          viewInsets: EdgeInsets.only(bottom: 300),
        ),
      ),
      isFalse,
    );
    expect(LoftifyGlassNavigationBar.shouldShowForKeyboard(normal), isTrue);
    expect(
      LoftifyGlassNavigationBar.shouldUseBlur(
        reduceMotion,
        enabled: true,
        isWeb: false,
      ),
      isFalse,
    );
    expect(
      LoftifyGlassNavigationBar.shouldUseBlur(normal, enabled: true, isWeb: false),
      isTrue,
    );
    expect(
      LoftifyGlassNavigationBar.shouldUseBlur(
        const MediaQueryData(size: Size(320, 640), highContrast: true),
        enabled: true,
        isWeb: false,
      ),
      isFalse,
    );
  });
}
