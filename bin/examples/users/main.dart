import 'package:dart_net_core_api/base_services/password_hash_service/password_hash_service.dart';
import 'package:dart_net_core_api/base_services/socket_service/socket_service.dart';
import 'package:dart_net_core_api/config.dart';
import 'package:dart_net_core_api/default_setups/controllers/auth_controller.dart';
import 'package:dart_net_core_api/default_setups/services/failed_password_blocking_service.dart';
import 'package:dart_net_core_api/default_setups/services/refresh_token_store_service.dart';
import 'package:dart_net_core_api/default_setups/services/user_store_service.dart';
import 'package:dart_net_core_api/jwt/jwt_service.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/utils/json_utils/json_serializer.dart';
import 'package:logging/logging.dart';

import 'controllers/user_controller.dart';
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
        PasswordHashService(),
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
      /// request and be destroyed along with controllers.
      /// For the services that are not supposed to be disposed of
      /// use `singletonServices`
      lazyServiceInitializer: {
        /// I added all store services to the lazy initializer
        /// because they open and close database connections
        UserStoreService: () => UserStoreService(),
        RefreshTokenStoreService: () => RefreshTokenStoreService(),
        FailedPasswordBlockingService: () => FailedPasswordBlockingService(),
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
