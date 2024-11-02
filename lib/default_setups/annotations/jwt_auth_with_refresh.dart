// import 'package:dart_net_core_api/default_setups/services/exports.dart';
// import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
import 'package:dart_net_core_api/jwt/annotations/jwt_auth.dart';
import 'package:dart_net_core_api/jwt/config/jwt_config.dart';
import 'package:dart_net_core_api/server.dart';

/// This attribute can added to the whole controller or
/// to a separate endpoint method. If it's applied to
/// an endpoint t will override the one applied to the
/// controller's class

/// You can add this attribute to [ApiController]s or
/// endpoints where you want your bearer tokens to be validated
/// by a refresh token publicKey.
///
/// Notice: this is not the best option if you want to set up
/// a microservice infrastructure since it requires a user database access
/// to get refresh tokens and take their payload.
///
/// But it has advantages as well. Foe example you can invalidated
/// all of your bearer tokens but just updating a refresh token in
/// a database. In this case, a public key will be updated and
/// the bearers will not be able to be validated against it
class JwtAuthWithRefresh extends JwtAuth {
  const JwtAuthWithRefresh({
    super.roles = const [],
  });

  @override
  Future authorize(HttpContext context) async {
    await super.authorize(context);
    final jwtConfig = context.getConfig<JwtConfig>()!;
    if (jwtConfig.useRefreshToken) {
      // final jwtService = context.getService<MongoRefreshTokenStoreService>()!;
      // final existingRefreshToken = await jwtService.findByUserId(
      //   userId: context.jwtPayload!.id,
      // );
      // if (existingRefreshToken == null ||
      //     existingRefreshToken.isExpired ||
      //     context.jwtPayload!.publicKey != existingRefreshToken.publicKey) {
      //   throw ApiException(
      //     message: 'Unauthorized',
      //     traceId: context.traceId,
      //     statusCode: HttpStatus.unauthorized,
      //     code: '401002',
      //   );
      // }
    }
  }
}
