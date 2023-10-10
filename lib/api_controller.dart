// ignore_for_file: unused_element

part of 'server.dart';

/// https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/
abstract class ApiController {
  

  HttpContext? _httpContext;
  HttpContext get httpContext => _httpContext!;

  void _setContext(HttpContext httpContext) {
    _httpContext = httpContext;
  }

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
  void dispose() { }
}