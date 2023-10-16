import 'package:dart_net_core_api/base_services/socket_service/socket_service.dart';

abstract class SocketAuthorization {
  const SocketAuthorization();

  /// [authorize] is called right after a client connection
  Future authorize(SocketClient client);
}

class SocketJwtAuthorization extends SocketAuthorization {

  const SocketJwtAuthorization();

  @override
  Future authorize(
    SocketClient client,
  ) async {
    print('authorize');
  }
}
