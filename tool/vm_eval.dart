import 'dart:convert';
import 'dart:io';

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

/// Evaluates an expression inside the running app's main library scope.
/// Usage: dart run tool/vm_eval.dart <ws-uri> '<dart expression>'
Future<void> main(List<String> arguments) async {
  if (arguments.length < 2) {
    stderr.writeln('Usage: dart run tool/vm_eval.dart <ws-uri> <expression>');
    exitCode = 64;
    return;
  }
  final service = await vmServiceConnectUri(
    Uri.parse(arguments[0]).replace(scheme: 'ws').toString(),
  );
  final vm = await service.getVM();
  final isolate = vm.isolates!.first;
  
  final response = await service.evaluate(
    isolate.id!,
    'package:loftify/main.dart',
    arguments[1],
  );
  if (response is InstanceRef) {
    stdout.writeln('result: ${jsonEncode(response.valueAsString)}');
  } else if (response is ErrorRef) {
    stderr.writeln('error: ${response.message}');
    exitCode = 1;
  } else {
    stdout.writeln('response: ${response.type}');
  }
  await service.dispose();
}
