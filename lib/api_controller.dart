part of 'server.dart';

abstract class ApiController {

  HttpContext? _httpContext;
  HttpContext get httpContext => _httpContext!;

  void _setContext(HttpContext httpContext) {
    _httpContext = httpContext;
  }
}