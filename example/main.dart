import 'package:dart_net_core_api/default_setups/controllers/health_controller.dart';
import 'package:dart_net_core_api/default_setups/controllers/profile_controller.dart';
import 'package:dart_net_core_api/exports.dart';
import 'package:dart_net_core_api/jwt/jwt_service.dart';

// import 'controllers/extended_auth_controller.dart';
import 'controllers/user_controller.dart';
import 'cron_jobs/every_minute_print_job.dart';

void main(List<String> arguments) {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  Server(
    /// This is the number of isolates that will be created
    /// for the server to handle requests
    numInstances: 2,
    settings: ServerSettings(
      arguments: arguments,
      apiControllers: [
        AuthController,
        ProfileController,
        AdminController,
        HealthController,
        DocumentationController,

        /// this is a controller that is documented
        UserController,
      ],
      configType: Config,
      cronJobs: [
        /// and example of a cron job that will be executed every minute
        /// and print a message with number of time the hob has been executed
        EveryMinutePrintJob(),
      ],
      singletonServices: [
        /// the built-in Json Web Token Service.
        /// If you don't need it
        /// you may implement your own authorization service
        JwtService(),

        /// If this service is added, the server will generate documentation
        /// for all controllers that have documentation annotations on every launch
        ApiDocumentationService(
          describeTypes: true,
        ),

        /// This service is used by the AuthController to block
        /// password login attempts if a password was incorrect for a few times
        FailedPasswordBlockingService(),

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
