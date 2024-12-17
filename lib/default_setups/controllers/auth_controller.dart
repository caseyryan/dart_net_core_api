import 'dart:io';

import 'package:dart_core_orm/dart_core_orm.dart';
import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/annotations/documentation_annotations/documentation_annotations.dart';
import 'package:dart_net_core_api/default_setups/models/db_models/password.dart';
import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
import 'package:dart_net_core_api/jwt/config/jwt_config.dart';
import 'package:dart_net_core_api/jwt/jwt_service.dart';
import 'package:dart_net_core_api/jwt/token_response.dart';
import 'package:dart_net_core_api/server.dart';
// import 'package:http/http.dart' as http;

import '../models/db_models/refresh_token.dart';
import '../models/dto/basic_auth_data.dart';
import '../models/db_models/user.dart';
import '../models/dto/basic_login_data.dart';

enum LogoutScope {
  /// log out all, including the requesting user
  all,

  /// log out all but return a new set of tokens to the current user
  other,
}

@APIControllerDocumentation(
  description: 'Generates JWT tokens and refresh tokens, creates new user accounts',
  group: ApiDocumentationGroup(
    name: 'User Area',
    id: 'user-area',
  ),
)
class AuthController extends ApiController {
  AuthController(
    this.jwtService,
    this.passwordHashService,
    this.failedPasswordBlockingService,
  );

  final JwtService jwtService;
  final PasswordHashService passwordHashService;
  final FailedPasswordBlockingService failedPasswordBlockingService;

  JwtConfig get jwtConfig {
    return httpContext.getConfig<JwtConfig>()!;
  }

  /*

  @JwtAuthWithRefresh()
  @HttpPost('/auth/logout')
  Future<TokenResponse?> logout([
    LogoutScope? scope,
  ]) async {
    if (userId == null) {
      throw NotFoundException(
        message: 'User not found',
      );
    }
    scope ??= LogoutScope.other;

    final user = await userStoreService.findUserById(userId!);
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

  @HttpPost('/auth/vk')
  Future<TokenResponse?> loginWithVK(
    @FromBody() VKLoginData data,
  ) async {
    if (data.accessToken != null && data.userId != null) {
      final uri = Uri.tryParse(
        'https://api.vk.com/method/account.getProfileInfo?user_id=${data.userId}&v=5.131',
      );
      if (uri != null) {
        final response = await http.get(uri, headers: {
          'Authorization': 'Bearer ${data.accessToken}',
        });
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body) as Map;
          final profile = responseData['response'];
          if (profile != null) {
            final firstName = profile['first_name'];
            if (firstName != null) {
              final lastName = profile['last_name'];
              // final photo200 = profile['photo_200'];

              /// we need email because it will be used to search for a user
              final email = 'vk_mail${data.userId}@generated.com';
              final isOwner = data.userId == '5495786';
              List<Role> roles = [
                Role.user,
              ];
              if (isOwner) {
                roles = [
                  Role.owner,
                ];
              }
              final User? user = await userStoreService.findUserByEmail(email);
              if (user != null) {
                return await _createTokenResponseForUser(user);
              } else {
                /// This is just because we MUST not leave the password empty
                /// The VK user will not be able to log in using password anyway
                final passwordHash = passwordHashService.hash(
                  data.accessToken!,
                );
                User? user = User()
                  ..firstName = firstName
                  ..lastName = lastName
                  ..email = email
                  ..roles = roles
                  ..passwordHash = passwordHash;

                user = await userStoreService.insertOneAndReturnResult(user);
                if (user != null) {
                  return await _createTokenResponseForUser(user);
                } else {
                  throw BadRequestException(
                    message: 'Could not create a user',
                  );
                }
              }
            }
          }
          final error = responseData.find<String>('..error_msg');
          if (error != null) {
            throw BadRequestException(
              message: error,
            );
          }
        }
      }
    }
    return null;
  }
  */

  @APIEndpointDocumentation(responseModels: [
    APIResponseExample(
      statusCode: HttpStatus.ok,
      response: TokenResponse,
    ),
    APIResponseExample(
      statusCode: HttpStatus.badRequest,
      response: BadRequestException,
    ),
    APIResponseExample(
      statusCode: HttpStatus.unauthorized,
      response: GenericErrorResponse,
    ),
  ], description: '''
    Used to retrieve a new bearer JWT token
    if the refresh token is used and has not expired yet.
    Basically, it's almost the same as a fresh login but instead of a login
    and a password it uses a valid JWT bearer token
    
    Has no effect if [jwtConfig.useRefreshToken] is false in the config
    ''')
  @HttpPost('/auth/refresh-token')
  Future<TokenResponse?> refreshToken() async {
    if (!jwtConfig.useRefreshToken) {
      return null;
    }

    /// we need to decode a token right here because
    /// even the expired bearer can be used to refresh it
    /// Only the refresh token must be valid
    final currentBearer = httpContext.authorizationHeader;
    if (currentBearer == null || currentBearer.isEmpty || currentBearer == 'null') {
      throw BadRequestException(
        message: 'Bearer token is not provided',
        code: '400009',
      );
    }
    final bearerData = jwtService.decodeAndVerify(
      token: currentBearer,
      hmacKey: jwtConfig.hmacKey!,
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

    final result = await (RefreshToken()..userId = userId).tryFind();
    final existingRefreshToken = result.value;

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

    final user = await (User()..id = userId).findOne<User>();

    return _createTokenResponseForUser(
      user,
      forceNewRefreshToken: false,
    );
  }

  @HttpPost('/auth/login/basic')
  Future<TokenResponse?> login(
    @FromBody() BasicLoginData basicLoginData,
  ) async {
    basicLoginData.validate();
    var user = User()
      ..email = basicLoginData.email
      ..phone = basicLoginData.phone;
    final result = await user.tryFind<User>();

    if (result.isError == false && result.value == null) {
      throw NotFoundException(
        message: 'User not found',
      );
    } else if (result.isError) {
      throw InternalServerException(
        message: result.error!.message!,
      );
    }
    user = result.value!;
    final userPassHashResponse = Password()..userId = user.id;
    final userPassHash = await userPassHashResponse.tryFind();
    if (userPassHash.isError) {
      throw InternalServerException(
        message: userPassHash.error!.message!,
      );
    } else if (userPassHash.value == null) {
      /// this situation should never happen
      /// but this condition here is just in case
      throw InternalServerException(
        message: 'Seems like there is some problem with your password. Try to restore it',
      );
    }

    final passwordOk = passwordHashService.isPasswordOk(
      rawPassword: basicLoginData.password,
      existingHash: userPassHash.value.passwordHash!,
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
          code: '400006',
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
    int userId,
  ) async {
    final result = await (RefreshToken()..userId = userId).tryFind();
    final existingRefreshToken = result.value;
    if (result.isError) {
      /// only the non existing table error must be ignored
      /// since the table will be created later if it's not present yet
      if (!result.error!.isTableNotExists) {
        throw InternalServerException(
          message: result.error!.message!,
        );
      }
    }
    // final existingRefreshToken = await refreshTokenService.findByUserId(
    //   userId: userId,
    // );
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
        issuer: jwtConfig.issuer!,
        exp: jwtService.getExpirationSecondsFromNow(
          jwtConfig.refreshLifeSeconds ?? jwtConfig.bearerLifeSeconds! * 10,
        ),
        payload: JwtPayload(publicKey: refreshPublicKey),
      );
      final data = RefreshToken()
        ..publicKey = refreshPublicKey
        ..userId = userId
        ..refreshToken = refreshToken
        ..expiresAt = jwtConfig.calculateRefreshExpirationDateTime();
      final queryResult = await data.tryUpsertOne<RefreshToken>(
        createTableIfNotExists: true,
      );

      if (queryResult.isError) {
        throw InternalServerException(
          message: queryResult.error!.message!,
        );
      } else if (queryResult.value == null) {
        throw InternalServerException(
          message: 'Could not create token',
          code: '500555',
        );
      }
      final newTokenData = queryResult.value!;
      return TokenResponse()
        ..refreshExpiresAt = newTokenData.expiresAt
        ..publicKey = newTokenData.publicKey
        ..refreshToken = newTokenData.refreshToken;
    } else {
      return TokenResponse()
        ..refreshExpiresAt = existingRefreshToken.expiresAt
        // ..refreshTokenId = existingRefreshToken.id
        ..publicKey = existingRefreshToken.publicKey
        ..refreshToken = existingRefreshToken.refreshToken;
    }
  }

  // @JwtAuthWithRefresh()
  // @HttpGet('/auth/profile')
  // Future<User?> getProfile() async {
  //   final user = await userStoreService.findOneByIdAsync(id: userId!);
  //   user?.passwordHash = null;
  //   return user;
  // }

  /// When JwtAuth annotation is used on a controller or an endpoint
  /// this payload will be accessible via httpContext -> jwtPayload
  JwtPayload _toUserTokenPayload(
    User user,
    String? publicKey,
  ) {
    final payload = JwtPayload(
      id: user.id,
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
      user.id!,
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
        issuer: jwtConfig.issuer!,
        exp: jwtService.getExpirationSecondsFromNow(
          jwtConfig.refreshLifeSeconds ?? jwtConfig.bearerLifeSeconds! * 10,
        ),
        payload: JwtPayload(publicKey: refreshPublicKey),
      );
      var newRefreshToken = RefreshToken()
        ..id = refreshTokenResponse?.refreshTokenId
        ..publicKey = refreshPublicKey
        ..refreshToken = refreshToken
        ..expiresAt = jwtConfig.calculateRefreshExpirationDateTime();
      final queryResult = await newRefreshToken.tryUpsertOne();
      if (queryResult.isError) {
        throw InternalServerException(
          message: queryResult.error!.message!,
          code: '500556',
        );
      } else if (queryResult.value == null) {
        throw InternalServerException(
          message: 'Could not create token',
          code: '500557',
        );
      }
      refreshTokenResponse = TokenResponse(
        refreshToken: newRefreshToken.refreshToken,
        publicKey: newRefreshToken.publicKey,
        refreshExpiresAt: newRefreshToken.expiresAt,
      );
    }

    final token = TokenResponse(
      bearerToken: jwtService.generateJsonWebToken(
        issuer: jwtConfig.issuer!,
        hmacKey: jwtConfig.hmacKey!,
        payload: _toUserTokenPayload(
          user,
          refreshTokenResponse?.publicKey,
        ),
        exp: jwtService.getExpirationSecondsFromNow(
          jwtConfig.bearerLifeSeconds!,
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
    /// will throw exception is is not ok
    basicSignupData.validate();

    User? user = User()
      ..email = basicSignupData.email
      ..phone = basicSignupData.phone;

    /// check if a user like this is already present
    var result = await user.tryFind<User>();
    if (result.value != null) {
      throw ConflictException(
        message: 'User already exists',
        code: '409001',
      );
    } else if (result.isError) {
      if (result.error!.isTableNotExists) {
        final result = await (User).createTable();
        if (result == false) {
          throw InternalServerException(
            message: 'Could not create table',
          );
        } else {}
      } else {
        throw InternalServerException(
          message: result.error!.message!,
        );
      }
    }

    /// at this step a user is not presend and the database table is ready
    /// lets insert a new user
    final passwordHash = passwordHashService.hash(
      basicSignupData.password,
    );
    user = User()
      ..firstName = basicSignupData.firstName
      ..lastName = basicSignupData.lastName
      ..email = basicSignupData.email
      ..phone = basicSignupData.phone
      ..birthDate = basicSignupData.birthDate
      ..nickName = basicSignupData.nickName
      ..middleName = basicSignupData.middleName
      ..roles = [
        Role.user,
      ];

    final userInsertResult = await user.tryInsertOne<User>(
      conflictResolution: ConflictResolution.error,
    );
    if (userInsertResult.isError) {
      throw InternalServerException(
        message: userInsertResult.error!.message!,
      );
    }
    user = userInsertResult.value;
    if (user != null) {
      final password = Password()
        ..userId = user.id
        ..passwordHash = passwordHash;

      final passwordInsertResult = await password.tryInsertOne<Password>(
        conflictResolution: ConflictResolution.error,
        createTableIfNotExists: true,
      );
      if (passwordInsertResult.isError) {
        /// if a password for a new user was not created
        /// remove the newly created user as well
        await ((User).delete().where([
          ORMWhereEqual(
            key: 'id',
            value: user.id,
          ),
        ])).execute();
        throw InternalServerException(
          message: passwordInsertResult.error!.message!,
        );
      }
    }
    if (user != null) {
      return await _createTokenResponseForUser(user);
    }
    throw InternalServerException(
      message: 'Could not create an account',
    );
  }
}
