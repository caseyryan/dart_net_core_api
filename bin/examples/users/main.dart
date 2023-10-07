import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/services/jwt_service.dart';
import 'package:dart_net_core_api/utils/json_utils/json_serializer.dart';
import 'package:dart_net_core_api/utils/server_utils/config/base_config.dart';

import 'controllers/auth_controller.dart';
import 'controllers/user_controller.dart';
import 'services/user_service.dart';

void main(List<String> arguments) {
  Server(
    arguments: arguments,
    apiControllers: [
      UserController,
      AuthController,
    ],
    configType: BaseConfig,
    // singletonServices: [
    //   UserService(),
    // ],
    lazyServiceInitializer: {
      UserService:() => UserService(),
      JwtService:() => JwtService(),
    },
    jsonSerializer: DefaultJsonSerializer(
      // CamelToSnake(),
      // FirstToUpper(),
      null,
    ),
    baseApiPath: '/api/v1',
  );
}
