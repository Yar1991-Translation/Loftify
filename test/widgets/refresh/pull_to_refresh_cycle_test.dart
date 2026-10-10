import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repro for "pull to refresh gets stuck in the refreshing stage on any
/// page": a full drag-past-trigger + release cycle must run the refresh task
/// and roll the header back to idle, both on a plain list and on the
/// `refreshOnStart: true` pages use.
void main() {
  Widget buildPage({
    required FutureOr<IndicatorResult> Function() onRefresh,
    bool refreshOnStart = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: EasyRefresh.builder(
          refreshOnStart: refreshOnStart,
          header: const LottieCupertinoHeader(
            indicator: SizedBox(width: 40, height: 40),
          ),
          onRefresh: onRefresh,
          childBuilder: (context, physics) => ListView(
            physics: physics,
            children: const [SizedBox(height: 900)],
          ),
        ),
      ),
    );
  }

  testWidgets('drag-release refresh runs and rolls the header back',
      (tester) async {
    final refreshCompleter = Completer<IndicatorResult>();
    var refreshCount = 0;

    await tester.pumpWidget(buildPage(onRefresh: () {
      refreshCount++;
      return refreshCompleter.future;
    }));
    await tester.pumpAndSettle();

    // Overscroll is heavily damped (~25% of finger travel), so drag far
    // enough to cross the 56px trigger.
    await tester.timedDrag(
      find.byType(ListView),
      const Offset(0, 500),
      const Duration(milliseconds: 600),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(refreshCount, 1, reason: 'releasing past the trigger must refresh');

    refreshCompleter.complete(IndicatorResult.success);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(refreshCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh after refreshOnStart completes still rolls back',
      (tester) async {
    final started = <Completer<IndicatorResult>>[];
    var refreshCount = 0;

    await tester.pumpWidget(buildPage(
      refreshOnStart: true,
      onRefresh: () {
        refreshCount++;
        final completer = Completer<IndicatorResult>();
        started.add(completer);
        return completer.future;
      },
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(refreshCount, 1, reason: 'refreshOnStart must fire the first load');
    started[0].complete(IndicatorResult.success);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // Now a user pull on the same page must also finish cleanly.
    await tester.timedDrag(
      find.byType(ListView),
      const Offset(0, 500),
      const Duration(milliseconds: 600),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(refreshCount, 2, reason: 'a manual pull must trigger a refresh');
    started[1].complete(IndicatorResult.success);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('an immediately completing refresh still rolls the header back',
      (tester) async {
    var refreshCount = 0;

    await tester.pumpWidget(buildPage(onRefresh: () async {
      refreshCount++;
      return IndicatorResult.success;
    }));
    await tester.pumpAndSettle();

    await tester.timedDrag(
      find.byType(ListView),
      const Offset(0, 500),
      const Duration(milliseconds: 600),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(refreshCount, 1);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
