import 'package:dart_net_core_api/base_services/socket_service/socket_service.dart';
import 'package:dart_net_core_api/jwt/config/jwt_config.dart';
import 'package:dart_net_core_api/jwt/jwt_service.dart';
import 'package:dart_net_core_api/server.dart';

/// Apply this annotation to [SocketController]
/// Notice: it can only be applied once. If you add several
/// [SocketNamespace] annotations, only the first one will take effect
class SocketNamespace {
  final String path;
  const SocketNamespace({
    required this.path,
  });
}

abstract class SocketAuthorization {
  const SocketAuthorization();

  /// [authorize] is called right after a client connection
  Future<Object?> authorize(
    SocketClient client,
    ServiceLocator serviceLocator,
  );
}

class SocketJwtAuthorization extends SocketAuthorization {
  const SocketJwtAuthorization();

  @override
  Future<Object?> authorize(
    SocketClient client,
    ServiceLocator serviceLocator,
  ) async {
    if (client.authorizationHeader == null) {
      throw 'Authorization token is missing';
    }
    final jwtService = serviceLocator<JwtService>();
    if (jwtService != null) {
      final jwtConfig = jwtService.getConfig<JwtConfig>()!;
      final bearerData = jwtService.decodeBearer(
        token: client.authorizationHeader!,
        config: jwtConfig,
      );
      final expSeconds = bearerData!['exp'] * 1000;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        expSeconds,
      );
      return expiresAt;
    }
  }
}
