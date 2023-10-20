// ignore_for_file: unused_element

import 'package:dart_net_core_api/annotations/socket_controller_annotations.dart';
import 'package:dart_net_core_api/base_services/socket_service/socket_service.dart';

/// This is the base class for a server-client socket communication
/// Extend this class to write a custom logic.
/// You can write methods and add annotations to them
abstract class SocketController {
  List<SocketAuthorization> _authAnnotations = [];

  /// This method is called dynamically. Do not remove!.
  /// You won't find any direct calls for it
  /// That's why I used ignore_for_file: unused_element at the top
  void _setAuthAnnotations(
    List<SocketAuthorization> value,
  ) {
    _authAnnotations = value;
  }

  Future tryCallAuthorization(
    SocketClient client,
  ) async {
    for (final annotation in _authAnnotations) {
      await annotation.authorize(client);
    }
  }
}
