part of '../../../server.dart';

class HttpContext {
  final String path;
  final String method;
  final String traceId;
  final HttpRequest httpRequest;
  final ServiceLocator serviceLocator;

  /// Might be used in JwtAuth annotation to
  /// be able to get the data from token
  JwtPayload? jwtPayload;

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
  });

  String get language {
    return headers.acceptLanguage ?? 'en-US';
  }

  T? getService<T extends Service>() {
    return serviceLocator(T) as T;
  }

  String? get authorizationHeader {
    return headers.authorization;
  }

  HttpHeaders get headers {
    return httpRequest.headers;
  }

  bool get shouldSerializeToJson {
    final primaryType = headers.contentType?.primaryType;
    final subType = headers.contentType?.subType;
    if (primaryType == null) {
      /// If no primary type is provided it will try to serialize 
      /// response to JSON
      return true;
    }
    return primaryType == ContentType.json.primaryType &&
        subType == ContentType.json.subType;
  }
}
