part of '../../../server.dart';

class HttpContext {
  final String path;
  final String method;
  final String traceId;
  final HttpRequest httpRequest;
  final ServiceLocator serviceLocator;

  late String _environment;
  late ConfigParser _configParser;

  bool get isDev => _environment == 'dev';
  bool get isProd => _environment == 'prod';
  bool get isStage => _environment == 'stage';

  T? getConfig<T extends IConfig>() {
    return _configParser.getConfig<T>();
  }

  HttpContext({
    required this.path,
    required this.method,
    required this.httpRequest,
    required this.serviceLocator,
    required this.traceId,
  }) {
    if (httpRequest.contentLength > 0) {}
  }

  String get language {
    return headers.acceptLanguage ?? 'en-US';
  }

  HttpHeaders get headers {
    return httpRequest.headers;
  }

  bool get shouldSerializeToJson {
    return headers.contentType?.primaryType == ContentType.json.primaryType &&
        headers.contentType?.subType == ContentType.json.subType;
  }
}