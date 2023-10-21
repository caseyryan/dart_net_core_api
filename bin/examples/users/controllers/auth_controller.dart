import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/jwt/config/jwt_config.dart';
import 'package:dart_net_core_api/jwt/jwt_service.dart';
import 'package:dart_net_core_api/jwt/token_response.dart';
import 'package:dart_net_core_api/server.dart';

import '../models/basic_auth_data.dart';
import '../services/user_service.dart';

class AuthController extends ApiController {
  AuthController(
    this.jwtService,
    this.userService,
  );

  final JwtService jwtService;
  final UserService userService;

  @HttpPost('/auth/signup')
  Future<TokenResponse?> authorizeByBearer(
    @FromBody() BasicAuthData authData,
  ) async {
    final jwtConfig = httpContext.getConfig<JwtConfig>();
    return TokenResponse(
      bearerToken: jwtService.generateBearer(
        config: jwtConfig!,
      ),
      bearerExpirationDateTimeUtc: jwtConfig.bearerExpirationDateTime,
    );
  }
}
