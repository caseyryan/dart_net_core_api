import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
import 'package:dart_net_core_api/jwt/config/jwt_config.dart';
import 'package:dart_net_core_api/jwt/jwt_service.dart';
import 'package:dart_net_core_api/jwt/token_response.dart';
import 'package:dart_net_core_api/server.dart';

import '../models/basic_auth_data.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class AuthController extends ApiController {
  AuthController(
    this.jwtService,
    this.userService,
  );

  final JwtService jwtService;
  final UserService userService;

  @HttpPost('/auth/signup')
  Future<TokenResponse?> signup(
    @FromBody() BasicAuthData authData,
  ) async {
    final jwtConfig = httpContext.getConfig<JwtConfig>();
    final user = User()
      ..email = authData.email
      ..passwordHash = authData.password;
    final success = await userService.insertOne(user);
    if (success) {
      return TokenResponse(
        bearerToken: jwtService.generateBearer(
          config: jwtConfig!,
        ),
        bearerExpirationDateTimeUtc: jwtConfig.bearerExpirationDateTime,
      );
    }
    throw ApiException(
      message: 'Could not create an account',
    );
  }
}
