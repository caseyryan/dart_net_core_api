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

/// Annotated any methods of your [SocketController]s
/// that you want to be callable remotely.
/// SocketService will subscribe to the events with the corresponding
/// names
class RemoteMethod {
  const RemoteMethod({
    required this.name,
    this.responseReceiverName,
  });

  /// [name] the name of the method to call. Basically, it's the name 
  /// of the event that a socket controller will listen to
  /// 
  /// It may not be the same as the method name in your code
  /// Just pick up some unique alphanumericName
  /// To call this method from a connected client, just send
  /// and event with the same name and corresponding parameters
  /// 
  /// Notice: the parameters might not be primitive types. 
  /// If the expected parameter type is a custom class it will be 
  /// deserialized from json using reflect_buddy
  final String name;

  /// [responseReceiverName] optional name of the client event which will
  /// transfer a serialized response of the 
  /// method if the server method is not [Void]
  final String? responseReceiverName;
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
      return jwtService.decodeAndVerify(
        token: client.authorizationHeader!,
        hmacKey: jwtConfig.hmacKey,
      );
    }
    return null;
  }
}
