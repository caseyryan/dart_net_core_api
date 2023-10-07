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

  /// This method is always called after the response if 
  /// finished. You can override it if you need to clean up some resources
  void dispose() { }
}