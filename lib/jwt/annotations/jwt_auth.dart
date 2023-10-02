import 'dart:io';

import 'package:dart_net_core_api/exceptions/api_exceptions.dart';

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
    print(context);
    // await Future.delayed(const Duration(milliseconds: 1000));
    if (roles.contains('user')) {
      throw ApiException(
        message: 'Unauthorized, bitch',
        traceId: context.traceId,
        statusCode: HttpStatus.unauthorized,
      );
    }
  }
}
