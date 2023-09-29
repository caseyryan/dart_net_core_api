import '../server.dart';

/// All the annotations used for controllers come here

abstract class ControllerAnnotation {
  const ControllerAnnotation();
}

class BaseApiPath extends ControllerAnnotation {
  /// You can use either enter an empty string or a format like this
  /// /api/v1 with leading slash and no trailing slashes
  ///
  /// But if you provide something like this /api/v1/ the trailing slash will
  /// be removed automatically, so it will work anyway
  const BaseApiPath(this.basePath);

  final String basePath;
}

/// Extend this class if you need to implement custom
/// authorization attribute.
///
/// This annotation can be used on a controller or on a method level
/// The method usage has a higher priority compared the controller's one
abstract class Authorization {
  const Authorization();
  Future authorize(HttpContext context);
}

/// [path] You can use either enter an empty string or a format like this
/// /api/v1 with leading slash and no trailing slashes
///
/// But if you provide something like this /api/v1/ the trailing slash will
/// be removed automatically, so it will work anyway
///
/// [method] is a RESTful api method name like GET, POST, PATCH etc.
/// You can also use [HttpGet], [HttpPost] and other ready to use annotations
abstract class EndpointAnnotation {
  const EndpointAnnotation(
    this.path,
    this.method,
  );

  final String path;
  final String method;
}

abstract class ParameterAnnotation {
  const ParameterAnnotation();
}

/// In case you want some method parameter to
/// contain data from a request body, just annotate
/// the parameter with this annotation and it will be skipped
/// while parsing query and path parameters but will be used
/// for body parsing
/// 
/// @HttpPut('/user/{:id}')
/// Future<String> updateUser({
///   @FromBody() Map? user,
/// }) async {
///   await Future.delayed(const Duration(milliseconds: 200));
///   return 'User id: $id: name: $name, ${httpContext.path}';
/// }
class FromBody extends ParameterAnnotation {
  const FromBody();
}

class HttpGet extends EndpointAnnotation {
  const HttpGet(String path) : super(path, 'GET');
}

class HttpPost extends EndpointAnnotation {
  const HttpPost(String path) : super(path, 'POST');
}

class HttpPatch extends EndpointAnnotation {
  const HttpPatch(String path) : super(path, 'PATCH');
}

class HttpPut extends EndpointAnnotation {
  const HttpPut(String path) : super(path, 'PUT');
}

class HttpDelete extends EndpointAnnotation {
  const HttpDelete(String path) : super(path, 'DELETE');
}
