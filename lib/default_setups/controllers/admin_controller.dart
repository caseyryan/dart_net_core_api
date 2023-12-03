import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/default_setups/annotations/jwt_auth_with_refresh.dart';
import 'package:dart_net_core_api/default_setups/models/mongo_models/user.dart';
import 'package:dart_net_core_api/default_setups/services/user_store_service.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/utils/server_utils/response_wrappers/paginated_response.dart';

@BaseApiPath('/api/v1/admin')
class AdminController extends ApiController {
  AdminController(
    this.userStoreService,
  );

  final UserStoreService userStoreService;


  
  @JwtAuthWithRefresh(roles: [
    Role.admin,
  ])
  @HttpGet('/user/all')
  Future<PaginatedResponse> getUsers({
    int page = 0,
    int limit = 20,
  }) async {
    final users = await userStoreService.findManyAsync(
      page: page,
      limit: limit,
    );

    return PaginatedResponse<User>(
      page: page,
      limit: limit,
      data: users,
    );
  }
}
