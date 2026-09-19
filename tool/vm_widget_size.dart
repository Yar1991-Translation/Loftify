import 'dart:convert';

import 'package:vm_service/vm_service_io.dart';

/// Dumps the widget tree (type + size + text) for nodes whose type or text
/// matches [pattern], to debug layout anomalies.
/// Usage: dart run tool/vm_widget_size.dart <ws-uri> <pattern>
Future<void> main(List<String> arguments) async {
  final service = await vmServiceConnectUri(arguments[0]);
  final pattern = arguments[1].toLowerCase();
  final isolate = (await service.getVM()).isolates!.first;
  const group = 'size-dump';
  final root = (await service.callServiceExtension(
    'ext.flutter.inspector.getRootWidget',
    isolateId: isolate.id!,
    args: const {'objectGroup': group},
  ))
      .json!['result']['valueId'] as String;
  final response = await service.callServiceExtension(
    'ext.flutter.inspector.getRootWidgetSummaryTree',
    isolateId: isolate.id!,
    args: {
      'objectGroup': group,
      'subtreeDepth': '40',
    },
  );
  final result = response.json?['result'];
  if (result is! Map<String, dynamic>) {
    print('unexpected response: ${jsonEncode(response.json)}');
    await service.dispose();
    return;
  }
  final tree = result;

  void walk(Map<String, dynamic> node, int depth) {
    final description = (node['description'] ?? '').toString();
    final text = (node['textPreview'] ?? node['value'] ?? '').toString();
    final size = node['size'];
    final haystack = '${description.toLowerCase()} ${text.toLowerCase()}';
    final matches = haystack.contains(pattern);
    if (matches) {
      print('${'  ' * depth}$description ${size ?? ''} $text');
    }
    for (final child in (node['children'] as List? ?? const [])) {
      if (child is Map<String, dynamic>) {
        walk(child, matches ? depth + 1 : depth);
      }
    }
  }

  walk(tree, 0);
  await service.dispose();
}
