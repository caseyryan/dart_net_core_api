import '../server.dart';

/// All the annotations used for controllers come here

abstract class ControllerAnnotation {
  const ControllerAnnotation();
}

/// Can be applied to a controller and set its defaults
/// The [defaultContentType] can be overridden in each
/// [EndpointAnnotation] for a particular endpoint
class Produces extends ControllerAnnotation {
  const Produces({
    required this.defaultContentType,
  });
  final String defaultContentType;
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
  const EndpointAnnotation({
    required this.path,
    required this.method,
    this.responseTypes,
    this.contentType = 'application/json; charset=utf-8',
  });

  final String path;
  final String method;
  final String contentType;
  final List<Object>? responseTypes;
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
  const HttpGet(
    String path, {
    String contentType = 'application/json; charset=utf-8',
    List<Object>? responseTypes,
  }) : super(
          path: path,
          method: 'GET',
          contentType: contentType,
          responseTypes: responseTypes,
        );
}

class HttpPost extends EndpointAnnotation {
  const HttpPost(
    String path, {
    String contentType = 'application/json; charset=utf-8',
    List<Object>? responseTypes,
  }) : super(
          path: path,
          method: 'POST',
          contentType: contentType,
          responseTypes: responseTypes,
        );
}

class HttpPatch extends EndpointAnnotation {
  const HttpPatch(
    String path, {
    String contentType = 'application/json; charset=utf-8',
    List<Object>? responseTypes,
  }) : super(
          path: path,
          method: 'PATCH',
          contentType: contentType,
          responseTypes: responseTypes,
        );
}

class HttpPut extends EndpointAnnotation {
  const HttpPut(
    String path, {
    String contentType = 'application/json; charset=utf-8',
    List<Object>? responseTypes,
  }) : super(
          path: path,
          method: 'PUT',
          contentType: contentType,
          responseTypes: responseTypes,
        );
}

class HttpDelete extends EndpointAnnotation {
  const HttpDelete(
    String path, {
    String contentType = 'application/json; charset=utf-8',
    List<Object>? responseTypes,
  }) : super(
          path: path,
          method: 'DELETE',
          contentType: contentType,
          responseTypes: responseTypes,
        );
}
