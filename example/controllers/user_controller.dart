import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/annotations/documentation_annotations/documentation_annotations.dart';
import 'package:dart_net_core_api/default_setups/models/db_models/abstract_user.dart';
import 'package:dart_net_core_api/jwt/annotations/jwt_auth.dart';
import 'package:dart_net_core_api/server.dart';

@BaseApiPath('/api/v1/users')
@JwtAuth(roles: [Role.user])
class UserController extends ApiController {
  UserController();

  @APIEndpointDocumentation(
    title: 'User Controller',
    responseModels: [APIResponseExample(statusCode: 200, response: AbstractUser)],
    description: 'Returns a list of users. Supports pagination and limits',
  )
  @HttpGet('/list')
  Future<List<AbstractUser>> getAllUsers({
    int page = 0,
    int limit = 20,
  }) async {
    return [
      AbstractUser()
        ..id = 1
        ..email = 'test@test.com'
        ..firstName = 'Vasya'
        ..lastName = 'Pupkin'
    ];
  }
}
