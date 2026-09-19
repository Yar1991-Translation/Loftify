import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

/// Triggers a hot reload on a running debug session.
/// Usage: dart run tool/vm_reload.dart <ws-uri>
Future<void> main(List<String> arguments) async {
  final service = await vmServiceConnectUri(arguments[0]);
  final isolate = (await service.getVM()).isolates!.first;
  final response = await service.reloadSources(isolate.id!);
  print('reload succeeded: ${response.success}');
  await service.dispose();
}
