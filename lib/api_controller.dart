// ignore_for_file: unused_element

part of 'server.dart';

/// https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/
abstract class ApiController {
  HttpContext? _httpContext;
  HttpContext get httpContext => _httpContext!;

  /// Override this method if you need to do anything 
  /// before the actual endpoint call and you don't want to do it in an 
  /// Annotation. By the moment this method is called, it is guaranteed that 
  /// [httpContext] is already assigned
  void onBeforeCall() {}

  HttpHeaders get headers {
    return httpContext.headers;
  }

  /// These properties are used simply as shorthands
  bool get isDev {
    return _httpContext?.isDev == true;
  }

  bool get isProd {
    return _httpContext?.isProd == true;
  }

  bool get isStage {
    return _httpContext?.isStage == true;
  }

  /// This method is always called after the response if
  /// finished. You can override it if you need to clean up some resources
  void dispose() {}
}
