import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/annotations/documentation_annotations/documentation_annotations.dart';
import 'package:dart_net_core_api/default_setups/models/db_models/user.dart';
import 'package:dart_net_core_api/server.dart';

@ControllerDocumentation(
  description: 'Works with users',
)
@BaseApiPath('/api/v1/users')
class UserController extends ApiController {
  UserController();

  @EndpointDocumentation(
    examples: [
      OpenApiResponseExample(
        statusCode: 200,
        response: User
      )
    ],
    description: 'Returns a list of users. Supports pagination and limits',
  )
  @HttpGet('/list')
  Future<List<User>> getAllUsers({
    int page = 0,
    int limit = 20,
  }) async {
    return [
      User()
        ..id = 1
        ..email = 'test@test.com'
        ..firstName = 'Vasya'
        ..lastName = 'Pupkin'
    ];
  }
}
