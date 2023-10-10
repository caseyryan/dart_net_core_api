import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/jwt/config/jwt_config.dart';
import 'package:dart_net_core_api/jwt/token_response.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/services/jwt_service.dart';

import '../models/basic_auth_data.dart';
import '../services/user_service.dart';

class AuthController extends ApiController {
  AuthController(
    this.jwtService,
    this.userService,
  );

  final JwtService jwtService;
  final UserService userService;

  @HttpPost('/auth/bearer')
  Future<TokenResponse?> authorizeByBearer(
    @FromBody() BasicAuthData authData,
  ) async {
    final jwtConfig = httpContext.getConfig<JwtConfig>();
    if (jwtConfig != null) {
      return TokenResponse(
        bearerToken: jwtService.generateBearer(
          config: jwtConfig,
        ),
        bearerExpirationDateTimeUtc: jwtConfig.bearerExpirationDateTime,
      );
    }
    return null;
  }
}
