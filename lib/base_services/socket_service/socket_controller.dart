import 'package:dart_net_core_api/annotations/socket_controller_annotations.dart';
import 'package:dart_net_core_api/base_services/socket_service/socket_service.dart';
import 'package:dart_net_core_api/utils/mirror_utils/simple_type_reflector.dart';

/// This is the base class for a server-client socket communication
/// Extend this class to write a custom logic.
/// You can write methods and add annotations to them
abstract class SocketController {
  final String namespace;
  SocketController({
    required this.namespace,
  }) {
    final reflection = SimpleTypeReflector(runtimeType);
    _authAnnotations = reflection.tryGetAnnotations<SocketAuthorization>();
  }

  late final List<SocketAuthorization> _authAnnotations;

  Future tryCallAuthorization(
    SocketClient client,
  ) async {
    for (final annotation in _authAnnotations) {
      await annotation.authorize(client);
    }
  }
}
