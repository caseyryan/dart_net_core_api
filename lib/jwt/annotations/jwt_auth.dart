import '../../annotations/controller_annotations.dart';
import '../../server.dart';

/// This attribute can added to the whole controller or
/// to a separate endpoint method. If it's applied to
/// an endpoint t will override the one applied to the
/// controller's class
class JwtAuth extends AuthorizationBase {
  final List<String>? roles;

  const JwtAuth({
    this.roles,
  });

  @override
  Future authorize(HttpContext context) async {
    print(context);
  }
}
