import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/jwt/annotations/jwt_auth.dart';
import 'package:dart_net_core_api/server.dart';

import '../models/user.dart';
import '../services/user_service.dart';

/// Even though baseApiPath '/api/v1' was
/// specified at [Server] initialization
/// [BaseApiPath] will override that value for this constructor
/// This is done here for demonstration purposes and is not obligatory
/// if you don't specify it here, the baseApiPath from [Server] will be
/// used instead
@BaseApiPath('/api/v2')
@JwtAuth()
class UserController extends ApiController {
  /// Notice [userService] is a dependency injection here
  /// If you specify a service in a constructor it will automatically
  /// be injected when the controller is instantiated
  /// you don't have to do it manually.
  /// In current scenario the service was initialized
  /// in [Server] constructor
  /// Server(
  ///   apiControllers: [
  ///     UserController,
  ///   ],
  ///   singletonServices: [
  ///     UserService(),
  ///   ],
  /// );
  UserController(
    this.userService,
  );

  final UserService userService;

  /// Default endpoint. Try calling it with Postman
  /// http://localhost:8084/api/v2/user/user-1
  /// IMPORTANT! the name of the variable must
  /// exactly match the name specified in the annotation path
  /// in this case it's `id`
  @HttpGet('/user/{:id}')
  Future<User?> getUser({
    required String id,
  }) async {
    return await userService.getUserById(id);
  }

  @HttpDelete('/user/{:id}')
  Future<User?> deleteUser({
    required String id,
  }) async {
    return await userService.deleteUserById(id);
  }

  @HttpPost('/user')
  Future<Object?> insertUser(
    @FromBody() User user,
  ) async {
    await userService.insertUser(user);
    return user;
  }

  /// You can use [dispose] to clean up 
  /// some resources if necessary
  @override
  void dispose() {
    print('controller disposed $this');
  }
}
