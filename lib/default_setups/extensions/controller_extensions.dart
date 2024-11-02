import 'package:dart_net_core_api/server.dart';

extension JwtApiControllerExtensions on ApiController {
  String? get userId {
    return httpContext.jwtPayload?.id?.toString();
  }

  List<Role> get requiredRoles {
    return httpContext.requiredRoles ?? [];
  }


  bool get isEditor {
    return httpContext.jwtPayload?.roles.contains(Role.editor) == true || isModerator;
  }

  bool get isModerator {
    return httpContext.jwtPayload?.roles.contains(Role.moderator) == true || isAdmin;
  }

  bool get isAdmin {
    return httpContext.jwtPayload?.roles.contains(Role.admin) == true || isOwner;
  }

  bool get isOwner {
    return httpContext.jwtPayload?.roles.contains(Role.owner) == true;
  }

}