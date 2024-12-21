// ignore_for_file: empty_catches

part of 'simple_type_reflector.dart';

class ControllerTypeReflector extends SimpleTypeReflector {
  ControllerTypeReflector(
    this.controllerType,

    /// [baseApiPath] which is provided in a [_Server] constructor.
    /// If you add BaseApiPath annotation to a controller, it will override the
    /// [baseApiPath] for that controller
    String baseApiPath,
  ) : super(
          controllerType,
          includeSuperClassPropertiesAndMethods: true,
        ) {
    final isApiController = _classMirror.isSubclassOf(
      reflectType(ApiController) as ClassMirror,
    );
    assert(
      isApiController,
      'The provided type: $controllerType does not extend $ApiController. All api controllers must inherit from $ApiController',
    );
    // if (constructors.length > 1) {
    //   throw 'A controller must have exactly one constructor but $controllerType has ${constructors.length}';
    // }

    _endpointMethods ??= methods
        .where((e) => e.hasEndpointAnnotations)
        .map(
          (e) => EndpointMethod(method: e),
        )
        .toList();
    final controllerAnnotations = super._annotations.whereType<ControllerAnnotation>().toList();
    final path = controllerAnnotations.whereType<BaseApiPath>().firstOrNull?.basePath ?? '';
    final controllerBasePathFromAnnotation = path.fixEndpointPath();
    if (controllerBasePathFromAnnotation.isNotEmpty) {
      basePath = controllerBasePathFromAnnotation;
    } else {
      basePath = baseApiPath;
    }
    final producesAnnotation = controllerAnnotations.whereType<Produces>().firstOrNull;
    _endpointMappers ??= [];
    for (var endpointMethod in _endpointMethods!) {
      int numBodyParams = 0;
      for (var p in endpointMethod.parameters) {
        if (p._annotations.whereType<FromBody>().isNotEmpty) {
          numBodyParams++;
          if (numBodyParams > 1) {
            final error = 'A method cannot contain more than one $FromBody annotation';
            print(error);
            throw error;
          }
        }
      }
      final endPointAnnotations = endpointMethod._annotations.whereType<EndpointAnnotation>();
      if (endPointAnnotations.length > 1) {
        throw 'An endpoint can have only one EndpointAnnotation. But $controllerType -> ${endpointMethod.name}() has ${endPointAnnotations.length}';
      }
      final endPointAnnotation = endPointAnnotations.first;
      _endpointMappers!.add(
        EndpointMapper(
          endpointMethod: endpointMethod,
          restMethodName: endPointAnnotation.method,
          fullPath: '$basePath${endPointAnnotation.path}',
          controllerTypeReflection: this,
          contentType: _getContentType(
            endPointAnnotation.contentType.isNotEmpty
                ? endPointAnnotation.contentType
                : producesAnnotation?.defaultContentType,
          ),
          responseTypes: endPointAnnotation.responseTypes,
        ),
      );
    }
  }

  static ContentType? _getContentType(String? value) {
    if (value != null) {
      try {
        return ContentType.parse(value);
      } catch (e) {}
    }
    return null;
  }

  ApiController? _instance;
  ApiController? get instance => _instance;

  Method get _constructor {
    return constructors.first;
  }

  /// Instantiates a controller passing all the necessary
  /// service instance to its constructor if necessary
  InstanceMirror instantiateController({
    required ServiceLocator serviceLocator,
    required ConfigParser configParser,
  }) {
    final positionalArgs = <dynamic>[];
    final Map<Symbol, dynamic> namedArguments = {};

    /// Only the services that are supposed to be destroyed
    /// after the endpoint call
    final List<Service> tempServices = [];
    for (var param in _constructor.parameters) {
      dynamic value;

      /// Instantiating a service might require some special actions
      /// So we check if it's a [Service] first
      if (param.isSubclassOf<Service>()) {
        final service = serviceLocator(param.reflectedType);
        if (service == null) {
          if (!param.isOptional) {
            throw 'Controller `$controllerType`` requires `${param.reflectedType}` service but it was not instantiated. Have you added it to the services list while creating a Server instance?';
          }
        }
        if (service?.isSingleton == false) {
          tempServices.add(service!);
        }
        value = service;

        /// calling a private method. This is made this way
        /// to avoid reveling it to other instances
        service!.callMethodByName(
          methodName: '_setConfigParser',
          positionalArguments: [
            configParser,
          ],
        );
        if (!service.isSingleton) {
          service.onReady();
        }
      } else {
        /// TODO: process other types too, not only services
      }
      if (value != null) {
        if (param.isNamed) {
          namedArguments[Symbol(param.name)] = value;
        } else {
          positionalArgs.add(value);
        }
      }
    }

    _instance = _classMirror
        .newInstance(
          Symbol.empty,
          positionalArgs,
          namedArguments,
        )
        .reflectee;

    _instance!.callMethodByName(
      methodName: '_setTempServices',
      positionalArguments: [
        tempServices,
      ],
    );

    return reflect(_instance);
  }

  List<EndpointMapper> tryFindEndpointMappers({
    required String path,
    required String method,
  }) {
    return _endpointMappers!
        .where(
          (e) => e.endpointPathParser.tryMatchPath(
            IncomingPathParser(path),
          ),
        )
        .toList();
  }

  /// Used for debugging. Prints all endpoints registered for this controller
  String? _allRegisteredEndpoints;
  String get allRegisteredEndpoints {
    if (_allRegisteredEndpoints != null) {
      return _allRegisteredEndpoints!;
    }
    if (_endpointMappers == null) {
      return '';
    }
    StringBuffer buffer = StringBuffer();
    for (EndpointMapper mapper in _endpointMappers!) {
      buffer.write(mapper.toFullPath());
      buffer.write(', ');
    }
    _allRegisteredEndpoints = buffer.toString();
    return _allRegisteredEndpoints!;
  }

  @override
  bool operator ==(covariant ControllerTypeReflector other) {
    return other.controllerType == controllerType;
  }

  @override
  int get hashCode {
    return controllerType.hashCode;
  }

  /// Used to check ambiguous endpoint paths
  static final List<EndpointMapper> _allMappers = [];

  late final String basePath;
  final Type controllerType;
  List<EndpointMethod>? _endpointMethods;
  List<EndpointMapper>? _endpointMappers;
}

class EndpointMapper {
  EndpointMapper({
    required this.endpointMethod,
    required this.restMethodName,
    required this.fullPath,
    required this.controllerTypeReflection,
    required this.contentType,
    required this.responseTypes,
  }) {
    endpointPathParser = EndpointPathParser(fullPath);
    final otherInstanceOrNull = ControllerTypeReflector._allMappers.firstWhereOrNull((e) => e == this);
    if (otherInstanceOrNull != null) {
      throw 'Ambiguous endpoint reference! $fullPath is already defined in ${otherInstanceOrNull.controllerTypeReflection.controllerType}';
    }
    ControllerTypeReflector._allMappers.add(this);
  }

  final EndpointMethod endpointMethod;
  final String restMethodName;
  final String fullPath;
  final ControllerTypeReflector controllerTypeReflection;
  ContentType? contentType;
  final List<Object>? responseTypes;
  late final EndpointPathParser endpointPathParser;

  /// This can only be set if [contentType] is null
  /// if it's not null, the content type from a request is ignored
  ContentType? _clientAcceptedContentType;

  void trySetContentTypeFromRequest(ContentType? value) {
    if (value == null || contentType != null) {
      return;
    }
    if (value.isJson || value.isAnyContent) {
      /// This is done this way to add a utf-8 charset
      _clientAcceptedContentType = ContentType.json;
    } else {
      _clientAcceptedContentType = value;
    }
  }

  ContentType? get responseContentType {
    return contentType ?? _clientAcceptedContentType;
  }

  bool get producesJson {
    final cType = contentType ?? _clientAcceptedContentType;
    final primaryType = cType?.primaryType;
    final subType = cType?.subType;
    if (primaryType == null) {
      return false;
    }
    return primaryType == ContentType.json.primaryType && subType == ContentType.json.subType;
  }

  FutureOr<Object?> tryCallEndpoint({
    required String path,
    required IServer server,
    required HttpContext httpContext,
    required ConfigParser configParser,
  }) async {
    final InstanceMirror controllerMirror = controllerTypeReflection.instantiateController(
      serviceLocator: server.tryFindServiceByType,
      configParser: configParser,
    );
    final ApiController controller = controllerMirror.reflectee;
    server.updateControllerContext(
      controller: controller,
      context: httpContext,
    );

    /// you can combine different auth annotations.
    /// For example you can use one that will check some
    /// necessary headers and another one will check auth bearer
    ///
    /// Notice: method annotations have the highest priority
    Iterable<Authorization> authAnnotations;
    authAnnotations = endpointMethod._annotations.whereType<Authorization>();
    if (authAnnotations.isEmpty) {
      authAnnotations = controllerTypeReflection._annotations.whereType<Authorization>();
    }

    if (authAnnotations.isNotEmpty) {
      for (var auth in authAnnotations) {
        await auth.authorize(httpContext);
      }
    }

    final incomingPathParser = IncomingPathParser(path);
    final List<dynamic> positionalArgs = [];
    final Map<Symbol, dynamic> namedArguments = {};
    final maxFileSizeBytes = configParser.getConfig<Config>()?.maxUploadFileSizeBytes ?? (100 * 1024 * 1024);
    final body = await tryReadRequestBody(
      httpContext.httpRequest,
      httpContext.traceId,
      maxFileSizeBytes,
    );

    /// by calling these we fill all path variables in
    /// the incomingPathParser
    endpointPathParser.tryMatchPath(incomingPathParser);
    for (var param in endpointMethod.parameters) {
      Object? value;
      if (param.isBodyParam) {
        if (body is Map) {
          value = server.settings.jsonSerializer?.fromJson(
                body,
                param.reflectedType,
              ) ??
              value;
        } else {
          value = body;
        }
      } else {
        final argument = incomingPathParser.tryFindQueryArgument(
          argumentName: param.name,
        );
        if (argument == null) {
          if (param.isRequired) {
            throw ApiException(
              message: 'Argument ${param.name} is required in $path',
              traceId: httpContext.traceId,
            );
          }
        }
        value = tryConvertQueryArgumentType(
          actual: argument?.value,
          expectedType: param.reflectedType,
          dateParser: server.settings.dateParser,
        );
      }
      if (value != null) {
        if (param.isPositional) {
          positionalArgs.add(value);
        } else {
          namedArguments[Symbol(param.name)] = value;
        }
      }
    }

    return controllerMirror
        .invoke(
          Symbol(endpointMethod.name),
          positionalArgs,
          namedArguments,
        )
        .reflectee;
  }

  String toFullPath() {
    return '$restMethodName: $fullPath';
  }

  @override
  bool operator ==(covariant EndpointMapper other) {
    return other.fullPath == fullPath && other.restMethodName == restMethodName;
  }

  @override
  int get hashCode {
    return Object.hash(
      fullPath.hashCode,
      restMethodName,
    );
  }
}

extension MethodParameterExtension on MethodParameter {
  bool get isBodyParam {
    return _annotations.any((a) => a is FromBody);
  }
}
