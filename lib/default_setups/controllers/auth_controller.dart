import 'dart:io';

import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/base_services/password_hash_service/password_hash_service.dart';
import 'package:dart_net_core_api/default_setups/annotations/jwt_auth_with_refresh.dart';
import 'package:dart_net_core_api/default_setups/extensions/controller_extensions.dart';
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

enum LogoutScope {
  /// log out all, including the requesting user
  all,

  /// log out all but return a new set of tokens to the current user
  other,
}

class AuthController extends ApiController {
  AuthController(
    this.jwtService,
    this.userStoreService,
    this.passwordHashService,
    this.refreshTokenService,
    this.failedPasswordBlockingService,
  );

  final JwtService jwtService;
  final UserStoreService userStoreService;
  final PasswordHashService passwordHashService;
  final RefreshTokenStoreService refreshTokenService;
  final FailedPasswordBlockingService failedPasswordBlockingService;

  JwtConfig get jwtConfig {
    return httpContext.getConfig<JwtConfig>()!;
  }

  @JwtAuthWithRefresh()
  @HttpPost('/auth/logout')
  Future<TokenResponse?> logout([
    LogoutScope? scope,
  ]) async {
    scope ??= LogoutScope.other;

    final user = await userStoreService.findUserById(userId);
    TokenResponse? tokenResponse;
    if (user != null) {
      tokenResponse = await _createTokenResponseForUser(
        user,
        forceNewRefreshToken: true,
      );
    }

    switch (scope) {
      case LogoutScope.all:

        /// null means success with no content, http status code 204
        return null;
      case LogoutScope.other:
        return tokenResponse;
    }
  }

  @HttpPost('/auth/refresh-token')
  Future<TokenResponse?> refreshToken() async {
    if (!jwtConfig.useRefreshToken) {
      return null;
    }

    /// we need to decode a token right here because
    /// even the expired bearer can be used to refresh it
    /// Only the refresh token must be valid
    final currentBearer = httpContext.authorizationHeader;
    if (currentBearer == null) {
      throw BadRequestException(
        message: 'Bearer token is required',
        code: '400009',
      );
    }
    final bearerData = jwtService.decodeAndVerify(
      token: httpContext.authorizationHeader!,
      hmacKey: jwtConfig.hmacKey,
      payloadType: JwtPayload,
      checkExpiresIn: false,
      checkNotBefore: false,
    );
    if (bearerData?['payload'] is! JwtPayload) {
      throw BadRequestException(
        message: 'Invalid token',
        code: '400010',
      );
    }
    final jwtPayload = bearerData!['payload'] as JwtPayload;
    final userId = jwtPayload.id;

    final existingRefreshToken = await refreshTokenService.findByUserId(
      userId: userId,
    );

    if (existingRefreshToken == null ||
        existingRefreshToken.isExpired ||
        jwtPayload.publicKey != existingRefreshToken.publicKey) {
      throw ApiException(
        message: 'Unauthorized',
        traceId: httpContext.traceId,
        statusCode: HttpStatus.unauthorized,
        code: '401012',
      );
    }

    final user = await userStoreService.findUserById(
      userId,
      throwErrorIfNotFound: true,
    );

    return _createTokenResponseForUser(
      user!,
      forceNewRefreshToken: false,
    );
  }

  @HttpPost('/auth/login/basic')
  Future<TokenResponse?> login(
    @FromBody() BasicLoginData basicLoginData,
  ) async {
    basicLoginData.validate();
    final user = await userStoreService.findUserByPhoneOrEmail(
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
        throw BadRequestException(message: error, code: '400006');
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
    final existingRefreshToken = await refreshTokenService.findByUserId(
      userId: userId,
    );
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
      final newTokenId = await refreshTokenService.insertOneAndReturnIdAsync(data);
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
    User user, {
    bool? forceNewRefreshToken,
  }) async {
    TokenResponse? refreshTokenResponse = await _getOrCreateRefreshToken(
      user.id,
    );
    bool createNewRefreshToken = false;
    if (jwtConfig.useRefreshToken) {
      createNewRefreshToken = forceNewRefreshToken ?? refreshTokenResponse?.isRefreshTokenExpired == true;
    }
    if (createNewRefreshToken) {
      /// Update the expired refresh token in a database
      final refreshPublicKey = passwordHashService.generatePublicKeyForRefresh();
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
    if (refreshTokenResponse != null && jwtConfig.useRefreshToken) {
      return token.copyWith(
        refreshToken: refreshTokenResponse.refreshToken,
        refreshExpiresAt: refreshTokenResponse.refreshExpiresAt,
      );
    }
    return token;
  }

  @HttpPost('/auth/signup/basic')
  Future<TokenResponse?> signup(
    @FromBody() BasicSignupData basicSignupData,
  ) async {
    basicSignupData.validate();
    final existingUser = await userStoreService.findUserByPhoneOrEmail(
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

    final id = await userStoreService.insertOneAndReturnIdAsync(user);
    user.id = id;
    if (id != null) {
      return await _createTokenResponseForUser(user);
    }
    throw InternalServerException(
      message: 'Could not create an account',
    );
  }
}
