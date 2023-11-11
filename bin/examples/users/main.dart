import 'package:dart_net_core_api/base_services/socket_service/socket_service.dart';
import 'package:dart_net_core_api/config.dart';
import 'package:dart_net_core_api/jwt/jwt_service.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/utils/json_utils/json_serializer.dart';
import 'package:logging/logging.dart';

import 'controllers/auth_controller.dart';
import 'controllers/user_controller.dart';
import 'services/user_service.dart';
import 'socket_namespaces/notification_socket_controller.dart';

void main(List<String> arguments) {
  
  Logger.root.level = Level.ALL;
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
        JwtService(),
        SocketService<SocketClient>(
          socketControllers: [
            /// a new instance of this controller will be created 
            /// for each connected socket client and 
            /// disposed of on the client disconnection
            /// Notice: each [SocketController] descendant 
            /// has a property called `client` which is the link to
            /// a Socket wrapper. It can be used to listen to socket events 
            /// or other purposes
            NotificationSocketController,
          ],
        ),
      ],
      /// Prefer lazyServiceInitializer for the type of 
      /// services that are supposed to live for a period of one 
      /// request and be destroyed with along with controllers. 
      /// For the services that are not supposed to be disposed of 
      /// use `singletonServices`
      lazyServiceInitializer: {
        UserService: () => UserService(),
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
