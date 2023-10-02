import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/utils/json_utils/json_serializer.dart';

import 'controllers/user_controller.dart';
import 'services/user_service.dart';

void main(List<String> arguments) {
  Server(
    apiControllers: [
      UserController,
    ],
    singletonServices: [
      UserService(),
    ],
    jsonSerializer: DefaultJsonSerializer(
      // CamelToSnakeConverter(),
      null,
    ),
    baseApiPath: '/api/v1',
  );
}
