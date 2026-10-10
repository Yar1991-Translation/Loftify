import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('debug pull-to-refresh state', (tester) async {
    final refreshCompleters = <Completer<IndicatorResult>>[];
    var refreshCount = 0;
    final log = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EasyRefresh.builder(
            refreshOnStart: true,
            header: const LottieCupertinoHeader(
              indicator: SizedBox(width: 40, height: 40),
            ),
            onRefresh: () {
              refreshCount++;
              log.add('onRefresh #$refreshCount');
              final completer = Completer<IndicatorResult>();
              refreshCompleters.add(completer);
              return completer.future;
            },
            childBuilder: (context, physics) => ListView(
              physics: physics,
              children: const [SizedBox(height: 900)],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    log.add('after start: count=$refreshCount');
    refreshCompleters[0].complete(IndicatorResult.success);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    final startData = EasyRefresh.of(tester.element(find.byType(ListView)));
    log.add('start settled: mode=${startData.headerNotifier.mode} '
        'offset=${startData.headerNotifier.offset.toStringAsFixed(1)}');

    final gesture = await tester.startGesture(const Offset(400, 300));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, 50));
      await tester.pump(const Duration(milliseconds: 16));
    }
    final armed = EasyRefresh.of(tester.element(find.byType(ListView)));
    log.add('armed: mode=${armed.headerNotifier.mode} '
        'offset=${armed.headerNotifier.offset.toStringAsFixed(1)}');
    await gesture.up();
    for (var i = 1; i <= 150; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final data = EasyRefresh.of(tester.element(find.byType(ListView)));
      if (i % 5 == 0 || i < 20) {
        log.add('t=${i * 16}ms: mode=${data.headerNotifier.mode} '
            'offset=${data.headerNotifier.offset.toStringAsFixed(4)} '
            'count=$refreshCount');
      }
    }

    // ignore: avoid_print
    print(log.join('\n'));
    expect(refreshCount, 2, reason: 'manual pull after refreshOnStart');
  });
}
