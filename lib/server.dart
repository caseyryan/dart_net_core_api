// ignore_for_file: await_only_futures

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:collection/collection.dart';
import 'package:dart_net_core_api/base_services/socket_service/socket_service.dart';
import 'package:dart_net_core_api/configs/mongo_config.dart';
import 'package:dart_net_core_api/configs/mysql_config.dart';
import 'package:dart_net_core_api/configs/postgresql_config.dart';
import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
import 'package:dart_net_core_api/utils/default_date_parser.dart';
import 'package:dart_net_core_api/utils/extensions/exports.dart';
import 'package:dart_net_core_api/utils/extensions/https_request_extensions.dart';
import 'package:dart_net_core_api/utils/json_utils/json_serializer.dart';
import 'package:dart_net_core_api/utils/mirror_utils/extensions.dart';
import 'package:dart_net_core_api/utils/mirror_utils/simple_type_reflector.dart';
import 'package:dart_net_core_api/utils/server_utils/any_logger.dart';
import 'package:dart_net_core_api/utils/server_utils/config/config_parser.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import 'package:reflect_buddy/reflect_buddy.dart' as rb;

import 'config.dart';
import 'jwt/jwt_service.dart';

part 'api_controller.dart';
part 'base_services/service.dart';
part 'utils/server_utils/environment_reader.dart';
part 'utils/server_utils/parts/http_context.dart';
part 'utils/server_utils/parts/http_request_extension.dart';
part 'utils/server_utils/parts/server_settings.dart';

enum Role {
  guest(0),
  user(1),
  editor(3),
  moderator(100),
  admin(200),
  owner(300);

  const Role(this.priority);
  final int priority;
}

typedef ExceptionHandler = Object? Function({
  required String traceId,
  required String message,
  required int statusCode,
  required HttpRequest request,
  String? code,
  Object? exception,
});

abstract class IServer {
  const IServer(this.settings);

  final ServerSettings settings;

  void updateControllerContext({
    required ApiController? controller,
    required HttpContext context,
  });

  T? tryFindServiceByType<T extends Service>([Type? serviceType]);
}

Future _runServerInIsolate(
  ServerSettings settings,
  int instanceNumber,
) async {
  final receivePort = ReceivePort(
    'isolate_$instanceNumber',
  );
  final isolate = await Isolate.spawn(
    (Object? message) {
      _Server(
        settings,
        instanceNumber,
      );
    },
    settings,
    errorsAreFatal: false,
  );
  isolate.addOnExitListener(receivePort.sendPort);
}

class Server {
  /// [numInstances] the number of isolates you want to spawn
  /// for your server instances. 2 by default
  Server({
    int numInstances = 2,
    required ServerSettings settings,
  }) {
    for (var i = 0; i < numInstances; i++) {
      _runServerInIsolate(settings, i);
    }
  }
}

class _Server extends IServer {
  HttpServer? _httpServer;
  HttpServer? _httpsServer;

  _Server(
    super.settings,
    int instanceNumber,
  ) {
    assert(
      settings.useHttp == true || settings.useHttps == true,
      'You must use at least one protocol',
    );

    if (settings.singletonServices?.isNotEmpty == true) {
      for (var s in settings.singletonServices!) {
        if (_singletonServices.containsKey(s.runtimeType)) {
          throw 'You have already instantiated ${s.runtimeType}';
        }
        _singletonServices[s.runtimeType] = s;
      }
    }
    if (settings.lazyServiceInitializer?.isNotEmpty == true) {
      _lazyServiceInitializer.addAll(settings.lazyServiceInitializer!);
    }
    if (settings.apiControllers?.isNotEmpty == true) {
      for (var ct in settings.apiControllers!) {
        _registerController(ct);
      }
    }
    if (settings.arguments?.isNotEmpty == true) {
      final argParser = ArgParser();
      argParser.addOption('configPath');
      argParser.addOption('env');
      _argResults = argParser.parse(settings.arguments!);
    }

    /// supports dev / prod / stage. By default it will be prod
    _environment = _readEnvironment(_argResults?['env'] ?? 'prod');
    _configParser = ConfigParser(
      configPath: _argResults!['configPath'],
      configType: settings.configType,
      server: this,
    );

    /// We need to pass configs to singleton services right here
    /// to make them ready
    for (Service service in _singletonServices.values) {
      _trySetServiceDependencies(service);
    }
    if (settings.jsonSerializer?.keyNameConverter != null) {
      /// set converter to use in reflect buddy
      rb.customGlobalKeyNameConverter = settings.jsonSerializer!.keyNameConverter;
    }

    _bindServer(
      useHttp: settings.useHttp,
      useHttps: settings.useHttps,
      ipV4Address: settings.ipV4Address,
      httpPort: settings.httpPort ?? _configParser.getConfig<Config>()?.httpPort ?? 8084,
      httpsPort: settings.httpsPort ?? _configParser.getConfig<Config>()?.httpsPort ?? 8085,
      securityContext: settings.securityContext ?? SecurityContext(),
      instanceNumber: instanceNumber,
    );
  }

  String get environment {
    return _environment;
  }

  late ConfigParser _configParser;
  late String _environment;

  /// If you pass launch arguments here, it will contain parsed parameters
  ArgResults? _argResults;
  final Map<Type, LazyServiceInitializer> _lazyServiceInitializer = {};
  final Map<Type, Service> _singletonServices = {};

  void addSingletonService(covariant Service service) {
    _singletonServices[service.runtimeType] = service;
    _trySetServiceDependencies(service);
  }

  void _trySetServiceDependencies(
    Service? service,
  ) {
    /// this is a special type of a built-in service
    /// which can nest socket controllers. That's why
    /// we need to instantiate them here
    if (service is SocketService) {
      service.callMethodByName(
        methodName: '_registerControllers',
        positionalArguments: [
          tryFindServiceByType,
          _configParser,
        ],
      );
    }
    service?.callMethodByName(
      methodName: '_setConfigParser',
      positionalArguments: [
        _configParser,
      ],
    );
    service?.callMethodByName(
      methodName: '_setServiceLocator',
      positionalArguments: [
        tryFindServiceByType,
      ],
    );
    service?.onReady();
  }

  /// Creates a service instance on demand.
  void addServiceLazily<T extends Service>({
    required LazyServiceInitializer initializer,
  }) {
    if (_lazyServiceInitializer.containsKey(T)) {
      throw 'You cannot add the same service twice: $T';
    }
    _lazyServiceInitializer[T] = initializer;
  }

  @override
  T? tryFindServiceByType<T extends Service>([Type? serviceType]) {
    final type = serviceType ?? T;
    Service? service;
    if (_lazyServiceInitializer.containsKey(type)) {
      service = _lazyServiceInitializer[type]!();
      service.isSingleton = false;
    } else {
      service = _singletonServices[type];
      service?.isSingleton = true;
    }
    _trySetServiceDependencies(
      service,
    );
    return service as T?;
  }

  @override
  void updateControllerContext({
    required ApiController? controller,
    required HttpContext context,
  }) {
    controller?._httpContext = context;
    controller?.onBeforeCall();
  }

  void _printStartMessage({
    required String url,
    required int instanceNumber,
  }) {
    if (_printDebugInfo) {
      print('Started API server instance ($instanceNumber) at: $url');
    }
  }

  bool get _printDebugInfo {
    return _configParser.getConfig<Config>()?.printDebugInfo == true;
  }

  Future _bindServer({
    required bool useHttp,
    required bool useHttps,
    required String ipV4Address,
    required int httpPort,
    required int httpsPort,
    required SecurityContext securityContext,
    required int instanceNumber,
  }) async {
    if (useHttp) {
      _printStartMessage(
        url: 'http://$ipV4Address:$httpPort',
        instanceNumber: instanceNumber,
      );

      _httpServer = await HttpServer.bind(
        ipV4Address,
        httpPort,
        shared: true,
      );
    }
    if (useHttps) {
      _printStartMessage(
        url: 'https://$ipV4Address:$httpsPort',
        instanceNumber: instanceNumber,
      );
      _httpsServer = await HttpServer.bindSecure(
        ipV4Address,
        httpsPort,
        securityContext,
        shared: true,
      );
    }
    _onServerBound();
  }

  void _onServerBound() {
    _httpServer?.listen(_onHttpRequest);
    _httpsServer?.listen(_onHttpRequest);
  }

  Future _onHttpRequest(HttpRequest request) async {
    final traceId = Uuid().v4();
    try {
      final method = request.method;
      final uri = request.requestedUri;
      final origin = uri.origin;
      final path = '${uri.path}?${uri.query}';

      request.ensureCharsetPresent();
      await _callEndpoint(
        origin: origin,
        method: method,
        path: path,
        request: request,
        traceId: traceId,
      );
    } catch (e) {
      _onRequestError(
        request: request,
        traceId: traceId,
        exception: ApiException(
          message: e.toString(),
          traceId: traceId,
          statusCode: 500,
        ),
      );
    }
  }

  Future<Object?> _onRequestError({
    required HttpRequest request,
    required String traceId,
    required ApiException exception,
  }) async {
    Object? result;
    ExceptionHandler? handler;
    if (exception.statusCode == 500) {
      handler = settings.custom500Handler ?? _defaultErrorHandler;
    } else if (exception.statusCode == 404) {
      handler = settings.custom404Handler ?? _defaultErrorHandler;
    } else {
      handler = _defaultErrorHandler;
    }
    String message;
    try {
      request.response.statusCode = exception.statusCode;

      try {
        message = exception.message;
      } catch (e, s) {
        logGlobal(
          level: Level.SEVERE,
          traceId: traceId,
          message: e,
          stackTrace: s,
        );
        message = 'Something went wrong';
      }

      result = handler(
        message: message,
        statusCode: request.response.statusCode,
        traceId: traceId,
        request: request,
        code: exception.code,
        exception: exception,
      );
    } catch (e, s) {
      logGlobal(
        level: Level.SEVERE,
        traceId: traceId,
        message: e,
        stackTrace: s,
      );
    } finally {
      request.response.close();
    }
    return result;
  }

  Object? _defaultErrorHandler({
    required String traceId,
    required String message,
    required int statusCode,
    required HttpRequest request,

    /// if it was converted from an [ApiException]
    /// its code might be passed here. This code is used to customize some
    /// error responses
    String? code,
    Object? exception,
  }) {
    final response = {
      'error': {
        'message': message,
        'traceId': traceId,
      }
    };
    if (code?.isNotEmpty == true) {
      response['error']!['code'] = code!;
    }

    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(response));
    return response;
  }
  

  Future _writeFileToResponse({
    required File file,
    required HttpResponse response,
  }) async {
    final fileContentType = file.mimeType?.toContentType();
    if (fileContentType != null) {
      response.headers.contentType = fileContentType;
    }
    await response.addStream(
      file.readAsBytes().asStream(),
    );
  }

  Future<dynamic> _callEndpoint({
    required String origin,
    required String method,
    required String path,
    required HttpRequest request,
    required String traceId,
  }) async {
    EndpointMapper? endpointMapper;

    bool notFound = true;
    final context = HttpContext(
      httpRequest: request,
      method: method,
      path: path,
      serviceLocator: tryFindServiceByType,
      traceId: traceId,
    )
      .._environment = environment
      .._configParser = _configParser;
    StringBuffer? endpoints;
    if (context.isDev) {
      endpoints = StringBuffer();
    }
    for (final controllerTypeReflection in _registeredControllers) {
      final endpointMappers = controllerTypeReflection.tryFindEndpointMappers(
        path: path,
        method: method,
      );
      if (endpoints != null) {
        /// This only happens for DEV environment
        /// to print all available endpoints if some is not found
        endpoints.writeln(
          controllerTypeReflection.allRegisteredEndpoints,
        );
      }
      if (endpointMappers.isNotEmpty) {
        notFound = false;
        endpointMapper = endpointMappers.firstWhereOrNull(
          (e) => e.restMethodName == method,
        );
        break;
      }
    }
    if (notFound) {
      // if (context.isDev) {
      //   print('is dev $endpointMappers');
      // }
      String message = 'Could not find the endpoint to process the request ${request.requestedUri.toString()}';
      if (endpoints != null) {
        message += '  All available:\n${endpoints.toString()}  ';
      }
      _onRequestError(
        request: request,
        traceId: traceId,
        exception: NotFoundException(
          message: message,
          traceId: traceId,
        ),
      );
      return;
    } else if (endpointMapper == null) {
      /// this means that the endpoint was found but with an incorrect method
      _onRequestError(
        request: request,
        traceId: traceId,
        exception: ApiException(
          message: 'Method not allowed: $method',
          traceId: traceId,
          statusCode: HttpStatus.methodNotAllowed,
        ),
      );
      return;
    } else {
      Object? result;
      try {
        /// The actual calling of an endpoint
        result = await endpointMapper.tryCallEndpoint(
          path: path,
          server: this,
          httpContext: context,
          configParser: _configParser,
        );
        if (endpointMapper.contentType == null) {
          /// If endpointMapper's contentType is null and the client's content type is null
          /// it will set the value to ContentType.json by default
          endpointMapper.trySetContentTypeFromRequest(
            request.acceptContentType,
          );
        }

        /// endpointMapper.responseContentType uses client's Accept header value if
        /// there is no Content-Type header forced by the endpoint itself
        request.response.headers.contentType = endpointMapper.responseContentType;
        if (result != null) {
          if (endpointMapper.producesJson && settings.jsonSerializer != null) {
            if (result is File) {
              if (request.acceptContentType.canAcceptFile) {
                await _writeFileToResponse(
                  file: result,
                  response: request.response,
                );
              }
              throw UnsupportedMediaException(
                message: 'Unsupported media type. Try providing a correct `Accept` header',
              );
            }
            result = settings.jsonSerializer!.tryConvertToJsonString(result);
            request.response.write(result);
          } else {
            if (result is File) {
              await _writeFileToResponse(
                file: result,
                response: request.response,
              );
            } else {
              request.response.write(result);
            }
          }
        } else {
          request.response.statusCode = HttpStatus.noContent;
        }
      } on ApiException catch (e) {
        e.traceId ??= traceId;
        result = await _onRequestError(
          request: request,
          traceId: traceId,
          exception: e,
        );
      } on String catch (e) {
        result = await _onRequestError(
          request: request,
          traceId: traceId,
          exception: ApiException(
            message: e,
            traceId: traceId,
          ),
        );
      }
      // on NoSuchMethodError catch (_) {
      //   result = await _onRequestError(
      //     request: request,
      //     traceId: traceId,
      //     exception: InternalServerException(
      //       message: 'Method with specified params not found for `$path`',
      //       traceId: traceId,
      //     ),
      //   );
      // }
      catch (e) {
        result = await _onRequestError(
          request: request,
          traceId: traceId,
          exception: InternalServerException(
            message: e.toString(),
            traceId: traceId,
          ),
        );
      } finally {
        try {
          endpointMapper.controllerTypeReflection.instance?.dispose();
        } catch (e, s) {
          logGlobal(
            level: Level.SEVERE,
            traceId: traceId,
            message: e,
            stackTrace: s,
          );
        }
      }

      request.response.close();
    }
    return null;
  }

  final List<ControllerTypeReflector> _registeredControllers = [];
  void _registerController(Type type) {
    if (_registeredControllers.any((c) => c.controllerType == type)) {
      throw 'You can\'t register the same controller more than once: $type';
    }
    final reflector = ControllerTypeReflector(
      type,
      settings.baseApiPath,
    );
    _registeredControllers.add(reflector);
  }
}
