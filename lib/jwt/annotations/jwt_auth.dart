import 'dart:io';

import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
import 'package:dart_net_core_api/jwt/config/jwt_config.dart';
import 'package:dart_net_core_api/jwt/jwt_service.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

import '../../annotations/controller_annotations.dart';
import '../../server.dart';

/// This attribute can added to the whole controller or
/// to a separate endpoint method. If it's applied to
/// an endpoint t will override the one applied to the
/// controller's class

class JwtAuth extends Authorization {
  final List<Role> roles;

  const JwtAuth({
    this.roles = const [],
  });

  void _forbid(HttpContext context) {
    throw ApiException(
      message: 'Not enough rights',
      traceId: context.traceId,
      statusCode: HttpStatus.forbidden,
    );
  }

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
    if (bearerData['payload'] is Map) {
      final JwtPayload payload = fromJson<JwtPayload>(
        bearerData['payload'],
      ) as JwtPayload;

      context.jwtPayload = payload;
      if (roles.isNotEmpty) {
        if (!payload.containsRequiredRoles(roles)) {
          _forbid(context);
        }
      }
    } else {
      if (roles.isNotEmpty) {
        _forbid(context);
      }
    }
  }
}
