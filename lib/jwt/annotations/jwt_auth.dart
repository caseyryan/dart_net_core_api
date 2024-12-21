import 'dart:io';

import 'package:dart_core_orm/dart_core_orm.dart';
import 'package:dart_net_core_api/default_setups/models/db_models/refresh_token.dart';
import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
import 'package:dart_net_core_api/jwt/config/jwt_config.dart';
import 'package:dart_net_core_api/jwt/jwt_service.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

import '../../annotations/controller_annotations.dart';
import '../../server.dart';

class JwtAuth extends Authorization {

  /// Specify the roles that are required to access this endpoint
  /// By default it's [Role.guest] which means that any registered user 
  /// will be able to access this endpoint. 
  /// E.g. if you specify [Role.moderator], on users with the role of 
  /// [Role.moderator] or higher will be able to access it.
  /// 
  /// You can also specify multiple roles like this:
  /// JwtAuth(roles: [Role.editor, Role.moderator] )
  final List<Role> roles;

  const JwtAuth({
    this.roles = const [
      Role.guest,
    ],
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
    /// it means that any registered user is allowed to visit this endpoint
    /// basically, it only requires a signup because by default a signed up
    /// user acquires a role of `user`, which is higher than guest
    /// and guest might be used ony in some custom scenarios
    if (roles.contains(Role.guest)) {
      return;
    }
    if (context.authorizationHeader?.isNotEmpty != true) {
      throw UnAuthorizedException(
        message: 'Unauthorized',
        traceId: context.traceId,
      );
    }

    final jwtService = context.getService<JwtService>()!;
    final jwtConfig = context.getConfig<JwtConfig>()!;
    if (jwtConfig.useRefreshToken) {
      final userId = context.jwtPayload!.id;
      final result = await (RefreshToken()..userId = userId).tryFind();
      final existingRefreshToken = result.value;

      if (existingRefreshToken == null ||
          existingRefreshToken.isExpired ||
          context.jwtPayload!.publicKey != existingRefreshToken.publicKey) {
        throw UnAuthorizedException(
          message: 'Unauthorized',
          traceId: context.traceId,
          code: '401002',
        );
      }
    }

    final bearerData = jwtService.decodeAndVerify(
      token: context.authorizationHeader!,
      hmacKey: jwtConfig.hmacKey!,
    );

    if (bearerData == null) {
      throw UnAuthorizedException(
        traceId: context.traceId,
      );
    }
    context.requiredRoles = roles;
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

  @override
  List<String> get rolesAsStringList {
    return roles.map((e) => e.name).toList();
  }

  @override
  List<String> get requiredHeaders {
    return [
      HttpHeaders.authorizationHeader,
    ];
  }
}
