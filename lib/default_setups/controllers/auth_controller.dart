import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/base_services/password_hash_service/password_hash_service.dart';
import 'package:dart_net_core_api/default_setups/services/failed_password_blocking_service.dart';
import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
import 'package:dart_net_core_api/jwt/config/jwt_config.dart';
import 'package:dart_net_core_api/jwt/jwt_service.dart';
import 'package:dart_net_core_api/jwt/token_response.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:mongo_dart/mongo_dart.dart';

import '../models/dto/basic_auth_data.dart';
import '../models/dto/basic_login_data.dart';
import '../models/mongo_models/refresh_token.dart';
import '../models/mongo_models/user.dart';
import '../services/refresh_token_store_service.dart';
import '../services/user_store_service.dart';

class AuthController extends ApiController {
  AuthController(
    this.jwtService,
    this.userService,
    this.passwordHashService,
    this.refreshTokenService,
    this.failedPasswordBlockingService,
  );

  final JwtService jwtService;
  final UserStoreService userService;
  final PasswordHashService passwordHashService;
  final RefreshTokenStoreService refreshTokenService;
  final FailedPasswordBlockingService failedPasswordBlockingService;

  JwtConfig get jwtConfig {
    return httpContext.getConfig<JwtConfig>()!;
  }

  @HttpPost('/auth/logout/all')
  Future logoutOnAll() async {}

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
      /// If a user has ran out of allowed password attempts
      /// we need to block the user for a specified period of time
      /// and return a corresponding error to him
      final error = await failedPasswordBlockingService.tryGetBlockingError(
        user.id,
      );
      if (error != null) {
        throw BadRequestException(
          message: error,
          code: '400006'
        );
      }

      throw BadRequestException(
        message: 'A login or a password is incorrect',
      );
    }
    /// On a successful login, we remove the password blocker
    await failedPasswordBlockingService.deleteByUserId(user.id);
    return await _createTokenResponseForUser(user);
  }

  Future<TokenResponse?> _getOrCreateRefreshToken(
    ObjectId userId,
  ) async {
    final existingRefreshToken = await refreshTokenService.findByUserId(userId);
    final shouldUseRefreshToken = jwtConfig.useRefreshToken;
    if (!shouldUseRefreshToken) {
      return null;
    }

    String? refreshToken;
    String? refreshPublicKey;
    if (existingRefreshToken == null) {
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
        ..expiresAt = jwtConfig.calculateRefreshExpirationDateTime();
      final newTokenId =
          await refreshTokenService.insertOneAndReturnIdAsync(data);
      if (newTokenId == null) {
        throw InternalServerException(
          message: 'Could not create token',
        );
      }
      return TokenResponse()
        ..refreshExpiresAt = jwtConfig.calculateRefreshExpirationDateTime()
        ..publicKey = refreshPublicKey
        ..refreshToken = refreshToken;
    } else {
      return TokenResponse()
        ..refreshExpiresAt = existingRefreshToken.expiresAt
        ..refreshTokenId = existingRefreshToken.id
        ..publicKey = existingRefreshToken.publicKey
        ..refreshToken = existingRefreshToken.refreshToken;
    }
  }

  /// When JwtAuth annotation is used on a controller or an endpoint
  /// this payload will be accessible via httpContext -> jwtPayload
  JwtPayload _toUserTokenPayload(
    User user,
    String? publicKey,
  ) {
    final payload = JwtPayload(
      id: user.id.toHexString(),
      roles: user.roles!,
    );
    payload.publicKey = publicKey;
    return payload;
  }

  Future<TokenResponse?> _createTokenResponseForUser(
    User user,
  ) async {
    TokenResponse? refreshTokenResponse = await _getOrCreateRefreshToken(
      user.id,
    );
    final createNewToken =
        refreshTokenResponse?.isRefreshTokenExpired == true &&
            jwtConfig.useRefreshToken;
    if (createNewToken) {
      /// Update the expired refresh token in a database
      final refreshPublicKey =
          passwordHashService.generatePublicKeyForRefresh();
      final refreshToken = jwtService.generateJsonWebToken(
        hmacKey: jwtConfig.refreshTokenHmacKey!,
        issuer: jwtConfig.issuer,
        exp: jwtService.getExpirationSecondsFromNow(
          jwtConfig.refreshLifeSeconds ?? jwtConfig.bearerLifeSeconds * 10,
        ),
        payload: JwtPayload(publicKey: refreshPublicKey),
      );
      final newRefreshToken = RefreshToken()
        ..publicKey = refreshPublicKey
        ..refreshToken = refreshToken
        ..expiresAt = jwtConfig.calculateRefreshExpirationDateTime();
      final success = await refreshTokenService.updateOneAsync(
        selector: {
          '_id': refreshTokenResponse?.refreshTokenId,
        },
        value: newRefreshToken,
      );
      if (!success) {
        return null;
      } else {
        refreshTokenResponse = TokenResponse(
          refreshToken: refreshToken,
          publicKey: refreshPublicKey,
          refreshExpiresAt: jwtConfig.calculateRefreshExpirationDateTime(),
        );
      }
    }

    final token = TokenResponse(
      bearerToken: jwtService.generateJsonWebToken(
        issuer: jwtConfig.issuer,
        hmacKey: jwtConfig.hmacKey,
        payload: _toUserTokenPayload(
          user,
          refreshTokenResponse?.publicKey,
        ),
        exp: jwtService.getExpirationSecondsFromNow(
          jwtConfig.bearerLifeSeconds,
        ),
      ),
      bearerExpiresAt: jwtConfig.calculateBearerExpirationDateTime(),
    );
    if (refreshTokenResponse != null) {
      return token.copyWith(
        refreshToken: refreshTokenResponse.refreshToken,
        refreshExpiresAt: refreshTokenResponse.refreshExpiresAt,
      );
    }
    return null;
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

    final id = await userService.insertOneAndReturnIdAsync(user);
    user.id = id;
    if (id != null) {
      return await _createTokenResponseForUser(user);
    }
    throw InternalServerException(
      message: 'Could not create an account',
    );
  }
}
