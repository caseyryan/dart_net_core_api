import 'package:dart_net_core_api/server.dart';

extension JwtApiControllerExtensions on ApiController {
  dynamic get userId {
    return httpContext.jwtPayload?.id;
  }
}