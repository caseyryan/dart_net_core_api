import 'package:dart_net_core_api/base_services/socket_service/socket_service.dart';

class SocketNamespace {
  final String path;
  const SocketNamespace({
    required this.path,
  });
}


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
    /// TODO: нужно тут клиенту время жизни токена возаращать в виде 
    /// дейт тайма, чтобы по истечении, клиент автоматически дисконнектился
    print('authorize');
  }
}
