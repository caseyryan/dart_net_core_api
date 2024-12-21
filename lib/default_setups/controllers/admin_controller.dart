import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
import 'package:dart_net_core_api/jwt/annotations/jwt_auth.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/utils/server_utils/response_wrappers/pageable.dart';



@BaseApiPath('/api/v1/admin')
@JwtAuth(roles: [Role.admin])
class AdminController extends ApiController {
  AdminController();

  @HttpGet('/user/all')
  Future<Pageable> getUsers({
    int page = 0,
    int limit = 20,
  }) async {
    // return await userStoreService.findManyAsync(
    //   page: page,
    //   limit: limit,
    // );
    throw NotFoundException(message: 'Not found');
  }
}
