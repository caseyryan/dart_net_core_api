import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/default_setups/annotations/jwt_auth_with_refresh.dart';
import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/utils/server_utils/response_wrappers/pageable.dart';

@BaseApiPath('/api/v1/admin')
class AdminController extends ApiController {
  AdminController();


  @JwtAuthWithRefresh(roles: [
    Role.admin,
  ])
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
