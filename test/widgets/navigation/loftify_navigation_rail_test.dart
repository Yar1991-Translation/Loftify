import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Widgets/Navigation/loftify_navigation_rail.dart';
import 'package:loftify/Widgets/loftify_icons.dart';
import 'package:loftify/generated/app_localizations.dart';

final _seedScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF14C2BB),
);

Widget _host({
  Size size = const Size(700, 1024),
  int? selectedIndex = 0,
  ValueChanged<int>? onDestinationSelected,
  List<Widget>? trailing,
}) {
  return MaterialApp(
    theme: ThemeData(colorScheme: _seedScheme),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(
        body: Row(
          children: [
            // Explicit height mirrors the bounded shell height the rail
            // gets inside the tablet Scaffold.
            SizedBox(
              height: size.height,
              child: LoftifyNavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected ?? (_) {},
                trailing: trailing,
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    ),
  );
}

NavigationRail _rail(WidgetTester tester) =>
    tester.widget<NavigationRail>(find.byType(NavigationRail));

void main() {
  testWidgets('keeps labels visible under the icons at every width',
      (tester) async {
    for (final size in [const Size(600, 1024), const Size(1280, 800)]) {
      await tester.pumpWidget(_host(size: size));
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(_rail(tester).extended, isFalse);
      expect(_rail(tester).labelType, NavigationRailLabelType.all);
      // The label sits under the icon as real laid-out text, not collapsed.
      final labelBox = tester.renderObject<RenderBox>(find.text('Home'));
      expect(labelBox.size.width, greaterThan(0));
    }
  });

  testWidgets('renders the four tab destinations with Loftify icons',
      (tester) async {
    await tester.pumpWidget(_host());
    expect(_rail(tester).destinations, hasLength(4));
    expect(find.byIcon(LoftifyIcons.home), findsWidgets);
    expect(find.byIcon(LoftifyIcons.search), findsWidgets);
    expect(find.byIcon(LoftifyIcons.activity), findsWidgets);
    expect(find.byIcon(LoftifyIcons.profile), findsWidgets);
  });

  testWidgets('forwards destination taps as tab indices', (tester) async {
    int? tapped;
    await tester.pumpWidget(
      _host(onDestinationSelected: (index) => tapped = index),
    );
    await tester.tap(find.byIcon(LoftifyIcons.profile));
    expect(tapped, 3);
  });

  testWidgets('clears the selection when selectedIndex is null',
      (tester) async {
    await tester.pumpWidget(_host(selectedIndex: null));
    expect(_rail(tester).selectedIndex, isNull);
    await tester.pumpWidget(_host(selectedIndex: 2));
    expect(_rail(tester).selectedIndex, 2);
  });

  testWidgets('pins trailing actions to the bottom of the rail',
      (tester) async {
    await tester.pumpWidget(
      _host(
        size: const Size(800, 1200),
        trailing: [
          TextButton(onPressed: () {}, child: const Text('Theme')),
        ],
      ),
    );
    expect(find.text('Theme'), findsOneWidget);
    final lastIcon = tester.getRect(find.byIcon(LoftifyIcons.profile).last);
    final trailingRect = tester.getRect(find.text('Theme'));
    // Below every destination, hugging the rail's bottom edge.
    expect(trailingRect.top, greaterThanOrEqualTo(lastIcon.bottom));
    final railBottom = tester.getRect(find.byType(NavigationRail)).bottom;
    expect(railBottom - trailingRect.bottom, lessThanOrEqualTo(24));
  });

  testWidgets('uses the M3 selection treatment', (tester) async {
    await tester.pumpWidget(_host());
    final rail = _rail(tester);
    expect(rail.indicatorColor, _seedScheme.secondaryContainer);
    expect(rail.selectedIconTheme?.color, _seedScheme.onSecondaryContainer);
    expect(rail.unselectedIconTheme?.color, _seedScheme.onSurfaceVariant);
  });
}
