import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/base_services/password_hash_service/password_hash_service.dart';
import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
import 'package:dart_net_core_api/jwt/config/jwt_config.dart';
import 'package:dart_net_core_api/jwt/jwt_service.dart';
import 'package:dart_net_core_api/jwt/token_response.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:mongo_dart/mongo_dart.dart';

import '../models/basic_auth_data.dart';
import '../models/basic_login_data.dart';
import '../models/refresh_token.dart';
import '../models/user.dart';
import '../services/refresh_token_store_service.dart';
import '../services/user_store_service.dart';

class AuthController extends ApiController {
  AuthController(
    this.jwtService,
    this.userService,
    this.passwordHashService,
    this.refreshTokenService,
  );

  final JwtService jwtService;
  final UserStoreService userService;
  final PasswordHashService passwordHashService;
  final RefreshTokenStoreService refreshTokenService;

  JwtConfig get jwtConfig {
    return httpContext.getConfig<JwtConfig>()!;
  }

  @HttpPost('/auth/login/basic')
  Future<TokenResponse?> login(
    @FromBody() BasicLoginData basicLoginData,
  ) async {
    basicLoginData.validate();
    final user = await userService.findUserByPhoneOrEmail(
      email: basicLoginData.email,
      phone: basicLoginData.phone,
    );
    if (user == null) {
      throw NotFoundException(
        message: 'User not found',
      );
    }
    final passwordOk = passwordHashService.isPasswordOk(
      rawPassword: basicLoginData.password,
      existingHash: user.passwordHash!,
    );
    if (!passwordOk) {
      throw BadRequestException(
        message: 'A login or a password is incorrect',
      );
    }
    final refreshToken = await _getOrCreateRefreshToken(
      user.id,
    );
    print(refreshToken);
    // final refreshData = jwtService.decodeBearer(
    //   token: user.refreshToken!,
    //   hmacKey: jwtConfig.refreshTokenHmacKey!,
    // );
    // print(refreshData);

    return null;
  }

  Future<TokenResponse?> _getOrCreateRefreshToken(
    ObjectId userId,
  ) async {
    final existing = await refreshTokenService.findByUserId(userId);
    final shouldUseRefreshToken = jwtConfig.useRefreshToken;
    if (!shouldUseRefreshToken) {
      return null;
    }

    String? refreshToken;
    String? refreshPublicKey;
    if (existing == null) {
      refreshPublicKey = passwordHashService.generatePublicKeyForRefresh();
      refreshToken = jwtService.generateJsonWebToken(
        hmacKey: jwtConfig.refreshTokenHmacKey!,
        issuer: jwtConfig.issuer,
        exp: jwtService.getExpirationSecondsFromNow(
          jwtConfig.refreshLifeSeconds ?? jwtConfig.bearerLifeSeconds * 10,
        ),
        payload: JwtPayload(publicKey: refreshPublicKey),
      );
      final data = RefreshToken()
        ..publicKey = refreshPublicKey
        ..userId = userId
        ..refreshToken = refreshToken
        ..expiresAt = jwtConfig.refreshExpirationDateTime;
      final newTokenId = await refreshTokenService.insertOneAndReturnId(data);
      if (newTokenId == null) {
        throw InternalServerException(
          message: 'Could not create token',
        );
      }
      return TokenResponse()
        ..refreshExpiresAt = jwtConfig.refreshExpirationDateTime
        ..publicKey = refreshPublicKey
        ..refreshToken = refreshToken;
    } else {
      return TokenResponse()
        ..refreshExpiresAt = existing.expiresAt
        ..publicKey = existing.publicKey
        ..refreshToken = existing.refreshToken;
    }
  }

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

    final passwordHash = passwordHashService.hash(
      basicSignupData.password,
    );
    final user = User()
      ..firstName = basicSignupData.firstName
      ..lastName = basicSignupData.lastName
      ..email = basicSignupData.email
      ..roles = [
        Role.user,
      ]
      ..passwordHash = passwordHash;

    final id = await userService.insertOneAndReturnId(user);
    if (id != null) {
      TokenResponse? refreshTokenResponse = await _getOrCreateRefreshToken(id);

      /// When JwtAuth annotation is used on a controller or an endpoint
      /// this payload will be accessible via httpContext -> jwtPayload
      final payload = JwtPayload(
        id: id.toHexString(),
        roles: user.roles!,
      );
      if (refreshTokenResponse?.publicKey != null) {
        payload.publicKey = refreshTokenResponse!.publicKey;
      }
      var tokenResponse = TokenResponse(
        bearerToken: jwtService.generateJsonWebToken(
          issuer: jwtConfig.issuer,
          hmacKey: jwtConfig.hmacKey,
          payload: payload,
          exp: jwtService.getExpirationSecondsFromNow(
            jwtConfig.bearerLifeSeconds,
          ),
        ),
        bearerExpiresAt: jwtConfig.bearerExpirationDateTime,
      );
      if (refreshTokenResponse != null) {
        return tokenResponse.copyWith(
          refreshToken: refreshTokenResponse.refreshToken,
          refreshExpiresAt: refreshTokenResponse.refreshExpiresAt,
        );
      }
      return tokenResponse;
    }
    throw ApiException(
      message: 'Could not create an account',
    );
  }
}
