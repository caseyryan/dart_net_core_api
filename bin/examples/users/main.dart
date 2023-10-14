import 'package:dart_net_core_api/base_services/socket_service.dart';
import 'package:dart_net_core_api/config.dart';
import 'package:dart_net_core_api/jwt/jwt_service.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/utils/json_utils/json_serializer.dart';

import 'controllers/auth_controller.dart';
import 'controllers/user_controller.dart';
import 'services/mongo_service.dart';
import 'services/user_service.dart';

void main(List<String> arguments) {
  Server(
    numInstances: 2,
    settings: ServerSettings(
      
      arguments: arguments,
      apiControllers: [
        UserController,
        AuthController,
      ],
      configType: Config,
      singletonServices: [
        MongoService(),
        SocketService(
          namespaces: [
            '/notifications'
          ],
        ),
      ],
      lazyServiceInitializer: {
        UserService: () => UserService(),
        JwtService: () => JwtService(),
      },
      jsonSerializer: DefaultJsonSerializer(
        // CamelToSnake(),
        // FirstToUpper(),
        null,
      ),
      baseApiPath: '/api/v1',
    ),
  );
}
