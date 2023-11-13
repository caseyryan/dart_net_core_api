import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/base_services/password_hash_service/password_hash_service.dart';
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
    this.passwordHashService,
  );

  final JwtService jwtService;
  final UserService userService;
  final PasswordHashService passwordHashService;

  @HttpPost('/auth/login/basic')
  Future<TokenResponse?> login() async {}

  @HttpPost('/auth/signup/basic')
  Future<TokenResponse?> signup(
    @FromBody() BasicSignupData basicSignupData,
  ) async {
    basicSignupData.validate();
    final existingUser = await userService.findUserByPhoneOrEmail(
      email: basicSignupData.email,
      phone: basicSignupData.phone,
    );
    if (existingUser != null) {
      throw ConflictException(
        message: 'User already exists',
        code: '409001',
      );
    }

    final jwtConfig = httpContext.getConfig<JwtConfig>()!;
    final passwordHash = passwordHashService.hash(
      password: basicSignupData.password,
    );
    final user = User()
      ..firstName = basicSignupData.firstName
      ..lastName = basicSignupData.lastName
      ..email = basicSignupData.email
      ..roles = [
        Role.user,
      ]
      ..passwordHash = passwordHash;

    final shouldUseRefreshToken = jwtConfig.useRefreshToken;
    String? refreshToken;
    String? refreshPublicKey;
    if (shouldUseRefreshToken) {
      refreshPublicKey = passwordHashService.generatePublicKeyForRefresh();
      refreshToken = jwtService.generateJsonWebToken(
        hmacKey: jwtConfig.refreshTokenHmacKey!,
        issuer: jwtConfig.issuer,
        exp: jwtService.getExpirationSecondsFromNow(
          jwtConfig.refreshLifeSeconds ?? jwtConfig.bearerLifeSeconds * 10,
        ),
        payload: JwtPayload(publicKey: refreshPublicKey),
      );
    }
    if (refreshToken != null) {
      user.refreshToken = refreshToken;
    }

    final id = await userService.insertOneAndReturnId(user);
    if (id != null) {
      /// When JwtAuth annotation is used on a controller or an endpoint
      /// this payload will be accessible via httpContext -> jwtPayload
      final payload = JwtPayload(
        id: id.toHexString(),
        roles: user.roles!,
      );
      if (refreshPublicKey != null) {
        payload.publicKey = refreshPublicKey;
      }
      return TokenResponse(
        bearerToken: jwtService.generateJsonWebToken(
          issuer: jwtConfig.issuer,
          hmacKey: jwtConfig.hmacKey,
          payload: payload,
          exp: jwtService.getExpirationSecondsFromNow(
            jwtConfig.bearerLifeSeconds,
          ),
        ),
        bearerExpiresAt: jwtConfig.bearerExpirationDateTime,
        refreshToken: refreshToken,
        refreshExpiresAt:
            shouldUseRefreshToken ? jwtConfig.refreshExpirationDateTime : null,
      );
    }
    throw ApiException(
      message: 'Could not create an account',
    );
  }
}
