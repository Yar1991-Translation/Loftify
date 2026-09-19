import 'dart:async';

import 'package:vm_service/vm_service_io.dart';

/// Samples Flutter frame durations from the VM timeline for [seconds] and
/// prints a summary (avg / p50 / p95 / max). A frame over ~16.7ms at 60Hz
/// (or ~8.3ms at 120Hz) is a dropped/slow frame.
/// Usage: dart run tool/vm_frames.dart <ws-uri> [seconds]
Future<void> main(List<String> arguments) async {
  final seconds = arguments.length > 1 ? int.parse(arguments[1]) : 10;
  final service = await vmServiceConnectUri(arguments[0]);
  final frameDurations = <double>[];
  int? frameBeginTs;

  final completer = Completer<void>();
  var rawEvents = 0;
  final rawNames = <String>{};
  final subscription = service.onTimelineEvent.listen((event) {
    rawEvents++;
    for (final timelineEvent in event.timelineEvents ?? const []) {
      final json = timelineEvent.json;
      if (json == null) continue;
      final name = json['name']?.toString() ?? '';
      if (name.isNotEmpty && rawNames.length < 40) rawNames.add(name);
      if (name != 'Frame') continue;
      final dur = json['dur'];
      if (dur is int) {
        // Complete ('X') events carry their duration directly.
        frameDurations.add(dur / 1000.0);
        continue;
      }
      // Otherwise pair begin/end records by timestamp.
      final phase = json['ph'];
      final ts = json['ts'];
      if (phase == 'b' && ts is int) {
        frameBeginTs = ts;
      } else if (phase == 'e' && ts is int && frameBeginTs != null) {
        frameDurations.add((ts - frameBeginTs!) / 1000.0);
        frameBeginTs = null;
      }
    }
  });

  await service.streamListen('Timeline');
  Timer(Duration(seconds: seconds), () {
    if (!completer.isCompleted) completer.complete();
  });
  await completer.future;
  await subscription.cancel();
  await service.dispose();

  if (frameDurations.isEmpty) {
    print('no Frame events captured (raw timeline events: $rawEvents; '
        'names: ${rawNames.take(15).join(', ')})');
    return;
  }
  frameDurations.sort();
  double at(double p) =>
      frameDurations[(frameDurations.length * p).clamp(0, frameDurations.length - 1).floor()];
  final over16 = frameDurations.where((d) => d > 16.7).length;
  final over33 = frameDurations.where((d) => d > 33.0).length;
  print('frames: ${frameDurations.length} over ${seconds}s');
  print('avg=${(frameDurations.reduce((a, b) => a + b) / frameDurations.length).toStringAsFixed(1)}ms '
      'p50=${at(0.5).toStringAsFixed(1)}ms p95=${at(0.95).toStringAsFixed(1)}ms '
      'max=${frameDurations.last.toStringAsFixed(1)}ms');
  print('slow frames: >16.7ms: $over16 (${(over16 / frameDurations.length * 100).toStringAsFixed(0)}%), '
      '>33ms: $over33');
}
