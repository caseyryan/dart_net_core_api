part of '../../../server.dart';

class HttpContext {
  final String path;
  final String method;
  final String traceId;
  final HttpRequest httpRequest;
  final ServiceLocator serviceLocator;


  /// here might be roles that this endpoint or a controller require
  /// See example in JwtAuth
  List<Role>? requiredRoles;

  InternetAddress? get remoteAddress {
    return httpRequest.connectionInfo?.remoteAddress;
  }

  String? get clientIpAddress {
    return remoteAddress?.address;
  }

  int? get localPort {
    return httpRequest.connectionInfo?.localPort;
  }

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

  
}
