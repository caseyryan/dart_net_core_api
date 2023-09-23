// ignore_for_file: await_only_futures

import 'dart:io';
import 'dart:mirrors';

// import 'package:mongo_dart/mongo_dart.dart';

import 'package:dart_net_core_api/utils/endpoint_path_parser.dart';
import 'package:dart_net_core_api/utils/mirror_utils/simple_type_reflector.dart';
import 'package:uuid/uuid.dart';

import 'utils/json_utils/json_serializer.dart';

part 'server_extensions/service.dart';

class HttpContext {
  final String path;
  final String method;
  final List<QuerySegment> requiredArgs;
  final List<QuerySegment> optionalArgs;
  final Server server;
  final HttpRequest httpRequest;

  HttpContext({
    required this.path,
    required this.method,
    required this.requiredArgs,
    required this.optionalArgs,
    required this.server,
    required this.httpRequest,
  });
}

class Response {
  final dynamic payload;

  Response(this.payload);
}

typedef ExceptionHandler = Response Function({
  String traceId,
  String message,
  int statusCode,
});

class Server {
  static const String tagError = 'ERROR';

  final int httpPort;
  final int httpsPort;
  final String baseApiPath;
  final String ipV4Address;
  final JsonSerializer jsonSerializer;
  final ExceptionHandler? status500Handler;

  HttpServer? _httpServer;
  HttpServer? _httpsServer;

  /// [baseApiPath] this path will be prepended to
  /// all controllers by default. But if you need a custom
  /// default path for a particular controller you can override this
  /// by adding a @BaseApiPath annotation to that controller's
  /// constructor. E.g
  ///  @BaseApiPath('/api/v2')
  ///  UserController() {}
  /// and your controller will use a custom path
  /// [jsonSerializer] is used to serialize endpoint responses
  /// you can simply return an instance of a class e.g. User
  /// and it will automatically be serialized to json
  /// [apiControllers] the list of controller types.
  /// It can be null or empty but if you also don't add
  /// standalone endpoints then this will mean the server is
  /// basically useless because there is no endpoint to call
  /// [singletonServices] a list of services that will be stored as
  /// singletons in this server instance. Notice that an separate instance will
  /// be created for each isolate
  /// [status500Handler] if you want to process default 500 error
  /// on your own, just pass this handler
  Server({
    this.baseApiPath = '/api/v1',
    this.httpPort = 8084,
    this.httpsPort = 8085,
    this.ipV4Address = '0.0.0.0',
    bool useHttp = true,
    bool useHttps = false,
    List<Type>? apiControllers,
    SecurityContext? securityContext,
    this.status500Handler,
    Map<Type, LazyServiceInitializer>? lazyServiceInitializer,
    List<Service>? singletonServices,
    this.jsonSerializer = const DefaultJsonSerializer(),
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

    _bindServer(
      useHttp: useHttp,
      useHttps: useHttps,
      ipV4Address: ipV4Address,
      httpPort: httpPort,
      httpsPort: httpsPort,
      securityContext: securityContext ?? SecurityContext(),
    );
  }

  final Map<Type, LazyServiceInitializer> _lazyServiceInitializer = {};
  final Map<Type, Service> _singletonServices = {};

  void addSingletonService(covariant Service service) {
    _singletonServices[service.runtimeType] = service;
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

  Service? tryGetServiceByType(Type serviceType) {
    if (_lazyServiceInitializer.containsKey(serviceType)) {
      return _lazyServiceInitializer[serviceType]!();
    }
    return _singletonServices[serviceType];
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
    // print(traceId);
    try {
      final method = request.method;
      final uri = request.requestedUri;
      final origin = uri.origin;
      final path = '${uri.path}?${uri.query}';
      await _callEndpoint(
        method: method,
        path: path,
        request: request,
        traceId: traceId,
      );
      request.response.write('$method -> ORIGIN: $origin, PATH: $path');
      request.response.close();
    } catch (e) {
      _on500Error(
        request: request,
        traceId: traceId,
        error: e,
      );
    }
  }

  void _logError(String tag, dynamic data) {
    /// TODO: добавить логгер
    print('[$tag] ${data.toString()}');
  }

  Future _on500Error({
    required HttpRequest request,
    required String traceId,
    required Object error,
  }) async {
    if (status500Handler != null) {
      try {
        request.response.statusCode = 500;
        String message = 'Something went wrong';
        try {
          message = (error as dynamic).message;
        } catch (e) {
          _logError(tagError, e);
        }

        final response = status500Handler!(
          message: message,
          statusCode: request.response.statusCode,
          traceId: traceId,
        );
        request.response.write(
          jsonSerializer.toJson(response),
        );
        request.response.close();
      } finally {
        request.response.write({});
        request.response.close();
      }
    }
  }

  Future<dynamic> _callEndpoint({
    required String method,
    required String path,
    required HttpRequest request,
    required String traceId,
  }) async {
    final key = '$method $path';
    print(path);
    // final _EndpointWrapper? endpoint = _endpoints[key];
    // final parser = EndpointPathParser(path);

    // if (endpoint != null) {
    //   final context = HttpContext(
    //     method: method,
    //     path: path,
    //     // requiredArgs: parser._querySegments,
    //     // optionalArgs: parser.optionalArgs,
    //     requiredArgs: [],
    //     optionalArgs: [],
    //     server: this,
    //     httpRequest: request,
    //   );
    //   try {
    //     return await endpoint.call(context);
    //   } on DartApiException catch (e) {
    //     _logError(tagError, e.message);
    //   } catch (e) {
    //     _logError(tagError, e);
    //   }
    // }
    return null;
  }

  bool _registerController(Type type) {
    final simpleTypeReflection = ControllerTypeReflector(type);
    final controllerInstance = simpleTypeReflection.instantiateController(
      serviceLocator: tryGetServiceByType,
    );
    print(controllerInstance);

    return true;
  }
}

List<DeclarationMirror> _getConstructors(
  ClassMirror mirror,
) {
  final constructors = mirror.declarations.values
      .where(
        (declare) => declare is MethodMirror && declare.isConstructor,
      )
      .toList();
  return constructors;
}
