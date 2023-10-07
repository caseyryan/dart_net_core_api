import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/services/jwt_service.dart';
import 'package:dart_net_core_api/utils/server_utils/config/base_config.dart';

import '../models/basic_auth_data.dart';

class AuthController extends ApiController {
  AuthController(this.jwtService);

  final JwtService jwtService;

  @HttpPost('/auth/bearer')
  Future<String?> authorizeByBearer(
    @FromBody() BasicAuthData authData,
  ) async {
    final jwtConfig = httpContext.getConfig<BaseConfig>()?.jwtConfig;
    if (jwtConfig != null) {
      final token = jwtService.generateBearer(config: jwtConfig);
      return token;
    }
    return null;
  }
}
