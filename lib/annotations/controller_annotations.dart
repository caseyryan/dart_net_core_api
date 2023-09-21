import '../server.dart';

abstract class ControllerAnnotation {
  const ControllerAnnotation();
}

class BaseApiPath extends ControllerAnnotation {
  final String basePath;

  const BaseApiPath(this.basePath);
}

/// Extend this class if you need to implement custom
/// authorization attribute.
abstract class AuthorizationBase {
  const AuthorizationBase();
  void authorize(HttpContext context);
}

abstract class MethodAnnotation {
  final String path;
  final String method;

  const MethodAnnotation(
    this.path,
    this.method,
  );
}

class HttpGet extends MethodAnnotation {
  const HttpGet(String path) : super(path, 'GET');
}

class HttpPost extends MethodAnnotation {
  const HttpPost(String path) : super(path, 'POST');
}

class HttpPatch extends MethodAnnotation {
  const HttpPatch(String path) : super(path, 'PATCH');
}

class HttpPut extends MethodAnnotation {
  const HttpPut(String path) : super(path, 'PUT');
}

class HttpDelete extends MethodAnnotation {
  const HttpDelete(String path) : super(path, 'DELETE');
}
