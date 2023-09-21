// ignore_for_file: await_only_futures

import 'dart:collection';
import 'dart:io';
import 'dart:mirrors';

// import 'package:mongo_dart/mongo_dart.dart';

import 'package:dart_net_core_api/utils/endpoint_path_parser.dart';
import 'package:uuid/uuid.dart';

import 'annotations/controller_annotations.dart';
import 'controllers/api_controller.dart';
import 'exceptions/base_exception.dart';
import 'utils/get_annotation_instance.dart';
import 'utils/json_utils/json_serializer.dart';

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

  final ClassMirror _baseApiControllerMirror = reflectClass(
    ApiController,
  );

  final List<_ControllerWrapper> _controllers = [];
  final Map<String, _EndpointWrapper> _endpoints = {};
  final int httpPort;
  final int httpsPort;
  final String baseApiPath;
  final String ipV4Address;
  final JsonSerializer jsonSerializer;
  final List<Type> serviceTypes;
  final ExceptionHandler? status500Handler;

  HttpServer? _httpServer;
  HttpServer? _httpsServer;

  final HashSet<dynamic> _initializedServices = HashSet();

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
  /// [serviceTypes] the list of types that will be lazily instantiated
  /// when they are necessary. You can declare controller
  /// constructors with these services and the services will be injected as
  /// dependencies at run time. The service can be any class. The main condition
  /// is that it must have a default constructor with no params
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
    required this.serviceTypes,
    this.jsonSerializer = const DefaultJsonSerializer(),
  }) {
    assert((baseApiPath.startsWith('/') && !baseApiPath.endsWith('/')) ||
        baseApiPath.isEmpty);
    assert(
      useHttp == true || useHttps == true,
      'You must use at least one protocol',
    );

    if (apiControllers?.isNotEmpty == true) {
      for (var ct in apiControllers!) {
        if (_tryRegisterController(ct)) {
          print('Controller $ct is registered successfully!');
        }
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
    print(traceId);
    try {
      final method = request.method;
      final uri = request.requestedUri;
      final origin = uri.origin;
      final path = uri.path;
      await _callEndpoint(
        method: method,
        path: path,
        request: request,
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
  }) async {
    final key = '$method $path';
    final _EndpointWrapper? endpoint = _endpoints[key];
    final parser = EndpointPathParser(path);

    if (endpoint != null) {
      final context = HttpContext(
        method: method,
        path: path,
        // requiredArgs: parser._querySegments,
        // optionalArgs: parser.optionalArgs,
        requiredArgs: [],
        optionalArgs: [],
        server: this,
        httpRequest: request,
      );
      try {
        return await endpoint.call(context);
      } on DartApiException catch (e) {
        _logError(tagError, e.message);
      } catch (e) {
        _logError(tagError, e);
      }
    }
    return null;
  }

  bool _tryRegisterController(Type type) {
    final mirror = reflectClass(type);
    if (_isApiController(mirror)) {
      final constructors = _getConstructors(mirror);
      if (constructors.length == 1) {
        final controllerWrapper = _ControllerWrapper.fromClassMirror(
          mirror,
        );
        final baseApiPathAttribute = getAnnotationInstanceOrNull<BaseApiPath>(
          mirror.metadata,
        );
        final apiPath = baseApiPathAttribute?.basePath ?? baseApiPath;
        controllerWrapper.setBasePath(apiPath);

        if (_controllers.contains(controllerWrapper)) {
          throw '${controllerWrapper.controllerName} has already been registered!';
        }
        for (var declarationMirror in mirror.declarations.values) {
          controllerWrapper._tryCreateEndpointFromDeclarationMirror(
            declarationMirror,
          );
        }
        _controllers.add(controllerWrapper);

        /// This won't allow you to add a duplicated endpoint
        /// no matter if it's a part of a controller or a standalone endpoint
        _checkIfEndpointAlreadyRegistered(controllerWrapper);
        for (var endpoint in controllerWrapper._endpoints) {
          _endpoints[endpoint.fullName] = endpoint;
        }
        print(_endpoints);
      }
      return true;
    } else {
      throw '$type is not an ApiController. All controllers' +
          ' must inherit from ApiController';
    }
  }

  void _checkIfEndpointAlreadyRegistered(
    _ControllerWrapper controllerWrapper,
  ) {
    if (_controllers.isNotEmpty) {
      for (var cw in _controllers) {
        if (cw != controllerWrapper) {
          for (var endpoint in controllerWrapper._endpoints) {
            if (cw.hasEndpoint(endpoint)) {
              throw '"$endpoint" is already registered in "${cw.controllerName}" but is also present in "${controllerWrapper.controllerName}." You cannot have more than one endpoint with the same method and the same path';
            }
          }
        }
      }
    }
  }

  bool _isApiController(ClassMirror mirror) {
    return mirror.isSubclassOf(_baseApiControllerMirror);
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

class _ControllerWrapper {
  String _basePath = '';

  void setBasePath(String basePath) {
    _basePath = basePath;
  }

  static final ClassMirror _baseHttpMethodAnnotation = reflectClass(
    MethodAnnotation,
  );

  final List<_EndpointWrapper> _endpoints = [];
  late String _controllerName;

  _ControllerWrapper.fromClassMirror(
    ClassMirror mirror,
  ) {
    _controllerName = MirrorSystem.getName(
      mirror.simpleName,
    );
  }
  String get controllerName => _controllerName;

  @override
  operator ==(covariant _ControllerWrapper other) {
    return _controllerName == other._controllerName;
  }

  @override
  int get hashCode {
    return _controllerName.hashCode;
  }

  /// [methodDeclarationMirror] an instance method mirror
  /// it must be used to call the endpoint
  void _tryCreateEndpointFromDeclarationMirror(
    DeclarationMirror methodDeclarationMirror,
  ) {
    for (var annotationInstanceMirror in methodDeclarationMirror.metadata) {
      if (annotationInstanceMirror.type.isSubclassOf(_baseHttpMethodAnnotation)) {
        final String path = annotationInstanceMirror.getField(Symbol('path')).reflectee;

        assert(path.startsWith('/') && !path.endsWith('/'));
        final String method =
            annotationInstanceMirror.getField(Symbol('method')).reflectee;
        final endpoint = _EndpointWrapper(
          method,
          path,
          annotationInstanceMirror,
          methodDeclarationMirror,
          _controllerName,
        );
        if (_endpoints.contains(endpoint)) {
          throw 'Duplicate endpoint $endpoint';
        }
        endpoint._setControllerBasePath(_basePath);
        _endpoints.add(endpoint);
        
      }
    }
  }

  bool hasEndpoint(_EndpointWrapper endpoint) {
    return _endpoints.contains(endpoint);
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.write('[ApiController ');
    buffer.write(runtimeType);
    buffer.writeln(']');
    for (var element in _endpoints) {
      buffer.write('  ');
      buffer.writeln(element.toString());
    }
    buffer.writeln('end -->');
    return buffer.toString();
  }
}

class _EndpointWrapper {
  final String method;
  final String path;
  final InstanceMirror httpMethodAnnotationMirror;
  final DeclarationMirror instanceMethodMirror;
  final String? controllerName;

  /// If this endpoint belongs to a controller, then
  /// in will be instantiated and saved to this map
  /// on first call to any of its methods
  static final Map<String, InstanceMirror?> _controllerInstanceMirrors = {};

  String _baseApiPath = '';
  late final EndpointPathParser _pathParser;

  _EndpointWrapper(
    this.method,
    this.path,
    this.httpMethodAnnotationMirror,
    this.instanceMethodMirror,
    this.controllerName,
  );

  void _setControllerBasePath(String basePath) {
    _baseApiPath = basePath;
    _pathParser = EndpointPathParser('$_baseApiPath/$path');
  }

  bool _checkIfMethodParametersOk(
    List<ParameterMirror> methodParams, {
    List<dynamic> positionalArguments = const [],
    Map<String, dynamic> namedArguments = const {},
  }) {
    List<String> errors = [];
    List<dynamic> requiredPositional = [];
    Map<String, dynamic> requiredNamed = {};
    int numExpectedNamed = 0;
    int numExpectedPositional = 0;

    for (var paramMirror in methodParams) {
      final paramName = MirrorSystem.getName(
        paramMirror.simpleName,
      );
      if (!paramMirror.hasDefaultValue) {
        if (paramMirror.isNamed) {
          requiredNamed[paramName] = paramMirror;
        } else {
          requiredPositional.add(paramMirror);
        }
      }

      if (paramMirror.isNamed) {
        numExpectedNamed++;
      } else {
        numExpectedPositional++;
      }
    }
    if (positionalArguments.length > numExpectedPositional) {
      errors.add('To many positional arguments');
    }
    if (namedArguments.length > numExpectedNamed) {
      errors.add('To many named arguments');
    }
    if (errors.isEmpty) {
      for (var i = 0; i < requiredPositional.length; i++) {
        final paramName = MirrorSystem.getName(
          requiredPositional[i].simpleName,
        );
        if (i >= positionalArguments.length) {
          errors.add('Missing required argument $paramName');
        } else {
          final ParameterMirror parameterMirror = requiredPositional[i];
          final expectedMirror = reflectClass(parameterMirror.type.reflectedType);
          final actualMirror = reflectClass(positionalArguments[i].runtimeType);
          final typeOk = actualMirror.isAssignableTo(expectedMirror);
          if (!typeOk) {
            final expectedTypeName = MirrorSystem.getName(expectedMirror.simpleName);
            final actualTypeName = MirrorSystem.getName(actualMirror.simpleName);
            errors.add(
              'Argument $paramName has a type of $actualTypeName. Expected type: $expectedTypeName',
            );
          }
        }
      }

      for (var kv in requiredNamed.entries) {
        final paramName = kv.key;
        if (!namedArguments.containsKey(paramName)) {
          errors.add('Missing required argument $paramName');
        } else {
          final parameterMirror = kv.value;
          final expectedMirror = reflectClass(parameterMirror.type.reflectedType);
          final actualMirror = reflectClass(namedArguments[paramName].runtimeType);
          final typeOk = actualMirror.isAssignableTo(expectedMirror);
          if (!typeOk) {
            final expectedTypeName = MirrorSystem.getName(expectedMirror.simpleName);
            final actualTypeName = MirrorSystem.getName(actualMirror.simpleName);
            errors.add(
              'Argument $paramName has a type of $actualTypeName. Expected type: $expectedTypeName',
            );
          }
        }
      }
    }

    if (errors.isNotEmpty) {
      final message = errors.join('\n');
      throw DartApiException(message, 'TRACE ID');
    }
    return true;
  }

  /// Service injection
  List<dynamic> _getServicesForControllerParams(
    List<ParameterMirror> paramMirrors,
    Server server,
  ) {
    final temp = [];
    for (var paramMirror in paramMirrors) {
      final expectedType = paramMirror.type.reflectedType;
      final typeName = MirrorSystem.getName(paramMirror.simpleName);
      if (!server.serviceTypes.contains(expectedType)) {
        throw DartApiException(
          'Service of type "$typeName" is not found. Make you you have added this type to "services" list while in Server constructor',
          'TRACE ID 3',
        );
      } else {
        if (!server._initializedServices.any(
          (s) => s.runtimeType == expectedType,
        )) {
          final serviceClassMirror = reflectClass(expectedType);
          final constructors = _getConstructors(serviceClassMirror);
          if (constructors.isNotEmpty) {
            final constructor = constructors.first as MethodMirror;
            final service = serviceClassMirror.newInstance(
              constructor.constructorName,
              [],
            ).reflectee;
            server._initializedServices.add(service);
            temp.add(service);
          }
        } else {
          temp.add(server._initializedServices.firstWhere(
            (s) => s.runtimeType == expectedType,
          ));
        }
      }
    }

    return temp;
  }

  Future<dynamic> call(HttpContext context) async {
    if (instanceMethodMirror.owner is ClassMirror && controllerName != null) {
      /// This list can be empty but never null
      final methodAuthAnnotations = getAnnotationOfType<AuthorizationBase>(
        instanceMethodMirror.metadata,
      );
      for (var auth in methodAuthAnnotations) {
        auth.authorize(context);
      }

      final classMirror = instanceMethodMirror.owner as ClassMirror;
      final constructors = _getConstructors(classMirror);
      if (constructors.isNotEmpty) {
        final constructor = constructors.first as MethodMirror;

        /// Controller dependency injection
        final services = _getServicesForControllerParams(
          constructor.parameters,
          context.server,
        );

        final declaredMethodParams = (instanceMethodMirror as MethodMirror).parameters;

        /// Simply checks if all the required params are present and their
        /// types are correct. If something is wrong it will throw an
        /// exception with all the details
        _checkIfMethodParametersOk(
          declaredMethodParams,
          positionalArguments: context.requiredArgs,
          /// TODO: сюда надо 
          namedArguments: {}
          // namedArguments: context.namedArgs,
        );
        if (!_controllerInstanceMirrors.containsKey(controllerName)) {
          _controllerInstanceMirrors[controllerName!] = classMirror.newInstance(
            constructor.constructorName,
            services,
          );
        }
        final controllerInstance = _controllerInstanceMirrors[controllerName]!;
        final result = await controllerInstance.invoke(
          instanceMethodMirror.simpleName,
          context.requiredArgs,
          // context.requiredArgs.map((key, value) => MapEntry(Symbol(key), value)),
        );
        return result.reflectee;
      }
    }
  }

  @override
  operator ==(covariant _EndpointWrapper other) {
    return fullName == other.fullName;
  }

  @override
  int get hashCode {
    return fullName.hashCode;
  }

  String get fullName {
    return '$method $_baseApiPath$path';
  }

  @override
  String toString() {
    return 'Endpoint: $fullName';
  }
}
