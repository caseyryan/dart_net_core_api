// ignore_for_file: await_only_futures

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:collection/collection.dart';
import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
import 'package:dart_net_core_api/utils/default_date_parser.dart';
import 'package:dart_net_core_api/utils/json_utils/json_serializer.dart';
import 'package:dart_net_core_api/utils/mirror_utils/simple_type_reflector.dart';
import 'package:dart_net_core_api/utils/server_utils/config/config_parser.dart';
import 'package:uuid/uuid.dart';

import 'utils/server_utils/config/base_config.dart';

part 'api_controller.dart';
part 'services/service.dart';
part 'utils/server_utils/environment_reader.dart';
part 'utils/server_utils/parts/http_context.dart';
part 'utils/server_utils/parts/http_request_extension.dart';





typedef ExceptionHandler = Object? Function({
  required String traceId,
  required String message,
  required int statusCode,
  required HttpRequest request,
});

class Server {
  static const String tagError = 'ERROR';

  final int httpPort;
  final int httpsPort;
  final String baseApiPath;
  final String ipV4Address;
  final DateParser dateParser;
  final ExceptionHandler? custom500Handler;
  final ExceptionHandler? custom404Handler;
  final JsonSerializer? jsonSerializer;

  HttpServer? _httpServer;
  HttpServer? _httpsServer;

  /// [arguments] a list of arguments from main method
  /// e.g.
  /// [
  //     "--configPath",
  //     "config.dev.json",
  //     "--env",
  //     "dev"
  // ]
  /// [baseApiPath] this path will be prepended to
  /// all controllers by default. But if you need a custom
  /// default path for a particular controller you can override this
  /// by adding a @BaseApiPath annotation to that controller's
  /// constructor. E.g
  ///  @BaseApiPath('/api/v2')
  ///  UserController() {}
  /// and your controller will use a custom path
  ///
  /// [jsonSerializer] is used to serialize endpoint responses
  /// if the Content-Type header is application/json
  /// you can simply return an instance of a class e.g. User
  /// and it will automatically be serialized to json
  /// NOTICE: If you don't need your responses to be serialized automatically
  /// just set [jsonSerializer] to null
  ///
  /// [apiControllers] the list of controller types.
  /// It can be null or empty but if you also don't add
  /// standalone endpoints then this will mean the server is
  /// basically useless because there is no endpoint to call
  ///
  /// [lazyServiceInitializer] an initializer that will create a service
  /// instance only on demand
  ///
  /// [singletonServices] a list of services that will be stored as
  /// singletons in this server instance. Notice that an separate instance will
  /// be created for each isolate
  ///
  /// [custom500Handler] if you want to process default 500 error
  /// on your own, just pass this handler
  ///
  /// [configType] is the type of your config. Basically it's just for the 
  /// purpose of a having a typed configuration. You can write your own class
  /// it will be deserialized using reflection
  ///
  /// [dateParser] a tool to convert string dates from params to a DateTime
  /// the default parser uses [DateTime.tryParse] but you can implement your own
  /// parser for any types of date representation
  Server({
    required List<String>? arguments,
    this.baseApiPath = '/api/v1',
    this.httpPort = 8084,
    this.httpsPort = 8085,
    this.ipV4Address = '0.0.0.0',
    bool useHttp = true,
    bool useHttps = false,
    List<Type>? apiControllers,
    SecurityContext? securityContext,
    this.custom500Handler,
    this.custom404Handler,
    Type configType = BaseConfig,
    this.jsonSerializer = const DefaultJsonSerializer(
      null,
    ),
    Map<Type, LazyServiceInitializer>? lazyServiceInitializer,
    List<IService>? singletonServices,
    this.dateParser = defaultDateParser,
  }) {
    assert(
      useHttp == true || useHttps == true,
      'You must use at least one protocol',
    );

    if (singletonServices?.isNotEmpty == true) {
      for (var s in singletonServices!) {
        if (_singletonServices.containsKey(s.runtimeType)) {
          throw 'You have already instantiated ${s.runtimeType}';
        }
        _singletonServices[s.runtimeType] = s;
      }
    }
    if (lazyServiceInitializer?.isNotEmpty == true) {
      _lazyServiceInitializer.addAll(lazyServiceInitializer!);
    }
    if (apiControllers?.isNotEmpty == true) {
      for (var ct in apiControllers!) {
        _registerController(ct);
      }
    }
    if (arguments?.isNotEmpty == true) {
      final argParser = ArgParser();
      argParser.addOption('configPath');
      argParser.addOption('env');
      _argResults = argParser.parse(arguments!);
    }

    /// supports dev / prod / stage. By default it will be prod
    _environment = _readEnvironment(_argResults!['env']);
    _configParser = ConfigParser(
      configPath: _argResults!['configPath'],
      configType: configType,
    );

    _bindServer(
      useHttp: useHttp,
      useHttps: useHttps,
      ipV4Address: ipV4Address,
      httpPort: httpPort,
      httpsPort: httpsPort,
      securityContext: securityContext ?? SecurityContext(),
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
  final Map<Type, IService> _singletonServices = {};

  void addSingletonService(covariant IService service) {
    _singletonServices[service.runtimeType] = service;
  }

  /// Creates a service instance on demand.
  void addServiceLazily<T extends IService>({
    required LazyServiceInitializer initializer,
  }) {
    if (_lazyServiceInitializer.containsKey(T)) {
      throw 'You cannot add the same service twice: $T';
    }
    _lazyServiceInitializer[T] = initializer;
  }

  IService? tryFindServiceByType(Type serviceType) {
    if (_lazyServiceInitializer.containsKey(serviceType)) {
      final newServiceInstance = _lazyServiceInitializer[serviceType]!();
      _lazyServiceInitializer.remove(serviceType);
      _singletonServices[serviceType] = newServiceInstance;
    }
    return _singletonServices[serviceType];
  }

  void updateControllerContext({
    required ApiController? controller,
    required HttpContext context,
  }) {
    controller?._httpContext = context;
  }

  Future _bindServer({
    required bool useHttp,
    required bool useHttps,
    required String ipV4Address,
    required int httpPort,
    required int httpsPort,
    required SecurityContext securityContext,
  }) async {
    if (useHttp) {
      print('STARTING DART CORE API at http://$ipV4Address:$httpPort');
      _httpServer = await HttpServer.bind(
        ipV4Address,
        httpPort,
      );
    }
    if (useHttps) {
      print('STARTING DART CORE API at https://$ipV4Address:$httpsPort');
      _httpsServer = await HttpServer.bindSecure(
        ipV4Address,
        httpsPort,
        securityContext,
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

  void _logError(
    String tag,
    dynamic error,
  ) {
    /// TODO: добавить логгер
    print('[$tag] ${error.toString()}');
  }

  Future _onRequestError({
    required HttpRequest request,
    required String traceId,
    required ApiException exception,
  }) async {
    ExceptionHandler? handler;
    if (exception.statusCode == 500) {
      handler = custom500Handler ?? _defaultErrorHandler;
    } else if (exception.statusCode == 404) {
      handler = custom404Handler ?? _defaultErrorHandler;
    } else {
      handler = _defaultErrorHandler;
    }
    String message;
    try {
      request.response.statusCode = exception.statusCode;

      try {
        message = exception.message;
      } catch (e, s) {
        _logError(tagError, {
          'traceId': traceId,
          'error': e.toString(),
          'stackTrace': s.toString(),
        });
        message = 'Something went wrong';
      }

      handler(
        message: message,
        statusCode: request.response.statusCode,
        traceId: traceId,
        request: request,
      );
    } catch (e, s) {
      _logError(tagError, {
        'traceId': traceId,
        'error': e.toString(),
        'stackTrace': s.toString(),
      });
    } finally {
      request.response.close();
    }
  }

  Object? _defaultErrorHandler({
    required String traceId,
    required String message,
    required int statusCode,
    required HttpRequest request,
  }) {
    final response = {
      'error': {
        'message': message,
        'traceId': traceId,
      }
    };
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(response));
    return response;
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
    ).._environment = environment
    .._configParser = _configParser;
    for (final controllerTypeReflection in _registeredControllers) {
      final endpointMappers = controllerTypeReflection.tryFindEndpointMappers(
        path: path,
        method: method,
      );
      if (endpointMappers.isNotEmpty) {
        notFound = false;
        endpointMapper = endpointMappers.firstWhereOrNull(
          (e) => e.restMethodName == method,
        );
        break;
      }
    }
    if (notFound) {
      _onRequestError(
        request: request,
        traceId: traceId,
        exception: NotFoundException(
          message: 'Could not find the endpoint to process the request',
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
      try {
        /// The actual calling of an endpoint
        final result = await endpointMapper.tryCallEndpoint(
          path: path,
          server: this,
          context: context,
        );
        if (result != null) {
          request.response.headers.contentType = request.headers.contentType;
          if (context.shouldSerializeToJson && jsonSerializer != null) {
            final converted = jsonSerializer!.tryConvertToJsonString(result);
            request.response.write(converted);
          } else {
            request.response.write(result);
          }
        } else {
          request.response.statusCode = HttpStatus.noContent;
        }
      } on ApiException catch (e) {
        e.traceId ??= traceId;
        _onRequestError(
          request: request,
          traceId: traceId,
          exception: e,
        );
      } on String catch (e) {
        _onRequestError(
          request: request,
          traceId: traceId,
          exception: ApiException(
            message: e,
            traceId: traceId,
          ),
        );
      } catch (e) {
        _onRequestError(
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
          _logError(tagError, {
            'traceId': traceId,
            'error': e.toString(),
            'stackTrace': s.toString(),
          });
        }
        request.response.close();
      }
    }
    return null;
  }

  final List<ControllerTypeReflector> _registeredControllers = [];
  void _registerController(Type type) {
    if (_registeredControllers.any((c) => c.controllerType == type)) {
      throw 'You can\'t register the same controller more than once: $type';
    }
    final simpleTypeReflection = ControllerTypeReflector(type, baseApiPath);
    _registeredControllers.add(simpleTypeReflection);
  }
}
