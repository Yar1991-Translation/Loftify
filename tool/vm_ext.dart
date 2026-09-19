import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

/// Calls a Flutter VM service extension on the running app.
/// Usage: dart run tool/vm_ext.dart <ws-uri> <extension> [key=value ...]
Future<void> main(List<String> arguments) async {
  if (arguments.length < 2) {

  }
  final service = await vmServiceConnectUri(arguments[0]);
  final isolate = (await service.getVM()).isolates!.first;
  final args = <String, String>{};
  for (final pair in arguments.skip(2)) {
    final index = pair.indexOf('=');
    if (index > 0) args[pair.substring(0, index)] = pair.substring(index + 1);
  }
  final response = await service.callServiceExtension(
    arguments[1],
    isolateId: isolate.id!,
    args: args,
  );
  print('response: ${response.json}');
  await service.dispose();
}
