import 'package:dart_net_core_api/base_services/password_hash_service/password_hash_service.dart';
import 'package:dart_net_core_api/default_setups/controllers/admin_controller.dart';
import 'package:dart_net_core_api/default_setups/controllers/auth_controller.dart';
import 'package:dart_net_core_api/default_setups/controllers/health_controller.dart';
import 'package:dart_net_core_api/exports.dart';
import 'package:dart_net_core_api/jwt/jwt_service.dart';

import 'controllers/user_controller.dart';

void main(List<String> arguments) {
  Logger.root.level = Level.ALL;
  Server(
    /// This is the number of isolates that will be created
    /// for the server to handle requests
    numInstances: 2,
    settings: ServerSettings(
      arguments: arguments,
      apiControllers: [
        AuthController,
        AdminController,
        HealthController,

        /// this is a controller that is documented
        UserController,
      ],
      configType: Config,
      singletonServices: [
        /// the built-in Json Web Token Service.
        /// If you don't need it
        /// you may implement your own authorization service
        JwtService(),

        /// This service helps generate password hashes in a
        /// built-it AuthController
        PasswordHashService(),
      ],

      /// Prefer lazyServiceInitializer for the type of
      /// services that are supposed to live for a period of one
      /// request and be destroyed along with controllers.
      /// For the services that are not supposed to be disposed of
      /// use `singletonServices`
      lazyServiceInitializer: {},
      jsonSerializer: DefaultJsonSerializer(
        /// it is preferred to work with PostgreSQL, though not required
        CamelToSnake(),
      ),
      baseApiPath: '/api/v1',
    ),
  );
}
