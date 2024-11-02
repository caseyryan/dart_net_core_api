// ignore_for_file: unused_element

part of 'server.dart';

/// https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/
abstract class ApiController {
  HttpContext? _httpContext;
  HttpContext get httpContext => _httpContext!;

  String get traceId {
    return httpContext.traceId;
  }

  /// Override this method if you need to do anything
  /// before the actual endpoint call and you don't want to do it in an
  /// Annotation. By the moment this method is called, it is guaranteed that
  /// [httpContext] is already assigned
  void onBeforeCall() {}

  HttpHeaders get headers {
    return httpContext.headers;
  }
  
  Directory? get staticFileDirectory {
    final config = httpContext.getConfig<Config>();
    return config?.staticFileDirectory;
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

  List<Service> _tempServices = const [];

  /// sets a list of single-use services that will be disposed
  /// after the endpoint call is ended
  void _setTempServices(List<Service> value) {
    _tempServices = value;
  }

  /// This method is always called after the response if
  /// finished. You can override it if you need to clean up some resources
  void dispose() {
    for (var service in _tempServices) {
      service.dispose();
    }
  }
}
