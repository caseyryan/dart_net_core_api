import 'dart:io';

import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
import 'package:dart_net_core_api/jwt/config/jwt_config.dart';
import 'package:dart_net_core_api/jwt/jwt_service.dart';

import '../../annotations/controller_annotations.dart';
import '../../server.dart';

/// This attribute can added to the whole controller or
/// to a separate endpoint method. If it's applied to
/// an endpoint t will override the one applied to the
/// controller's class
class JwtAuth extends Authorization {
  final List<String> roles;

  const JwtAuth({
    this.roles = const [],
  });

  @override
  Future authorize(HttpContext context) async {
    if (context.authorizationHeader?.isNotEmpty != true) {
      throw ApiException(
        message: 'Unauthorized',
        traceId: context.traceId,
        statusCode: HttpStatus.unauthorized,
      );
    }

    final jwtService = context.getService<JwtService>();
    final bearerData = jwtService!.decodeBearer(
      token: context.authorizationHeader!,
      config: context.getConfig<JwtConfig>()!,
    );
    if (bearerData == null) {
      throw ApiException(
        message: 'Unauthorized',
        traceId: context.traceId,
        statusCode: HttpStatus.unauthorized,
      );
    }
  }
}
