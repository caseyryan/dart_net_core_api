part of 'simple_type_reflector.dart';

final _oddEndSlashRegexp = RegExp(r'[\/]+$');
final _oddStartSlashRegexp = RegExp(r'^[\/]+');

/// just removes unnecessary slashes from endpoint
/// declaration. So you may write /api/v1/ or even
/// /api/v1//// and it will still use the correct
/// record /api/v1 without a trailing slash
String _fixEndpointPath(String path) {
  final result =
      path.replaceAll(_oddEndSlashRegexp, '').replaceAll(_oddStartSlashRegexp, '/');
  if (result.isNotEmpty) {
    if (!result.startsWith('/')) {
      return '/$result';
    }
  }
  return result;
}

class ControllerTypeReflector extends SimpleTypeReflector {
  ControllerTypeReflector(
    this.controllerType,

    /// [baseApiPath] which is provided in a [Server] constructor.
    /// If you add BaseApiPath annotation to a controller, it will override the
    /// [baseApiPath] for that controller
    String baseApiPath,
  ) : super(controllerType) {
    assert(
      isApiController,
      'The provided type: $controllerType does not extend $ApiController. All api controllers must inherit from $ApiController',
    );
    if (constructors.length > 1) {
      throw 'A controller must have exactly one constructor but $controllerType has ${constructors.length}';
    }

    _endpointMethods ??= methods.where((e) => e.hasEndpointAnnotations).toList();
    final controllerAnnotations =
        super._annotations.whereType<ControllerAnnotation>().toList();
    if (controllerAnnotations.length > 1) {
      throw 'A controller can\'t have more that one ControllerAnnotation but $controllerType has ${controllerAnnotations.length}';
    }
    final controllerAuthAnnotations = controllerAnnotations.whereType<Authorization>();
    if (controllerAuthAnnotations.length > 1) {
      throw 'A controller can\'t have more that one AuthorizationAnnotation but $controllerType has ${controllerAuthAnnotations.length}';
    }

    final controllerBasePathFromAnnotation = _fixEndpointPath(
      controllerAnnotations.whereType<BaseApiPath>().firstOrNull?.basePath ?? '',
    );
    if (controllerBasePathFromAnnotation.isNotEmpty) {
      basePath = controllerBasePathFromAnnotation;
    } else {
      basePath = baseApiPath;
    }
    _endpointMappers ??= [];
    for (var em in _endpointMethods!) {
      int numBodyParams = 0;
      for (var p in em.parameters) {
        if (p._annotations.whereType<FromBody>().isNotEmpty) {
          numBodyParams++;
          if (numBodyParams > 1) {
            throw 'A method cannot contain more than one $FromBody annotation';
          }
        }
      }
      final endPointAnnotations = em._annotations.whereType<EndpointAnnotation>();
      final authAnnotations = em._annotations.whereType<Authorization>();
      if (endPointAnnotations.length > 1) {
        throw 'An endpoint can have only one EndpointAnnotation. But $controllerType -> ${em.name}() has ${endPointAnnotations.length}';
      }
      if (authAnnotations.length > 1) {
        throw 'An endpoint can have only one AuthorizationAnnotation. But $controllerType -> ${em.name}() has ${authAnnotations.length}';
      }
      final endPointAnnotation = endPointAnnotations.first;
      _endpointMappers!.add(
        EndpointMapper(
          instanceMethod: em,
          restMethodName: endPointAnnotation.method,
          fullPath: '$basePath${endPointAnnotation.path}',
          controllerTypeReflection: this,
        ),
      );
    }
  }

  Method get _constructor {
    return constructors.first;
  }

  /// Instantiates a controller passing all the necessary
  /// service instance to its constructor if necessary
  InstanceMirror instantiateController({
    required ServiceLocator serviceLocator,
  }) {
    final positionalArgs = <dynamic>[];
    final Map<Symbol, dynamic> namedArguments = {};
    for (var param in _constructor.parameters) {
      final service = serviceLocator(param.reflectedType);
      if (service == null) {
        if (!param.isOptional) {
          throw 'Controller $controllerType requires ${param.type} service but it was not instantiated!';
        }
      }
      if (param.isNamed) {
        namedArguments[Symbol(param.name)] = service;
      } else {
        positionalArgs.add(service);
      }
    }

    final instance = _classMirror
        .newInstance(
          Symbol.empty,
          positionalArgs,
          namedArguments,
        )
        .reflectee;
    return reflect(instance);
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
  List<Method>? _endpointMethods;
  List<EndpointMapper>? _endpointMappers;
}

class EndpointMapper {
  EndpointMapper({
    required this.instanceMethod,
    required this.restMethodName,
    required this.fullPath,
    required this.controllerTypeReflection,
  }) {
    endpointPathParser = EndpointPathParser(fullPath);
    final otherInstanceOrNull =
        ControllerTypeReflector._allMappers.firstWhereOrNull((e) => e == this);
    if (otherInstanceOrNull != null) {
      throw 'Ambiguous endpoint reference! $fullPath is already defined in ${otherInstanceOrNull.controllerTypeReflection.controllerType}';
    }
    ControllerTypeReflector._allMappers.add(this);
  }

  final Method instanceMethod;
  final String restMethodName;
  final String fullPath;
  final ControllerTypeReflector controllerTypeReflection;
  late final EndpointPathParser endpointPathParser;

  FutureOr<Object?> tryCallEndpoint({
    required String path,
    required Server server,
    required HttpContext context,
  }) async {
    final InstanceMirror controllerMirror = controllerTypeReflection.instantiateController(
      serviceLocator: server.tryFindServiceByType,
    );
    
    server.updateControllerContext(
      controller: controllerMirror.reflectee,
      context: context,
    );
    final authAnnotation =
        instanceMethod._annotations.whereType<Authorization>().firstOrNull ??
            controllerTypeReflection._annotations.whereType<Authorization>().firstOrNull;
    if (authAnnotation != null) {
      await authAnnotation.authorize(context);
    }

    final incomingPathParser = IncomingPathParser(path);
    final List<dynamic> positionalArgs = [];
    final Map<Symbol, dynamic> namedArguments = {};
    final body = await tryReadRequestBody(
      context.httpRequest,
      context.traceId,
    );

    /// by calling these we fill all path variables in
    /// the incomingPathParser
    endpointPathParser.tryMatchPath(incomingPathParser);
    for (var param in instanceMethod.parameters) {
      Object? value;
      if (param.isBodyParam) {
        value = body;
      } else {
        final argument = incomingPathParser.tryFindQueryArgument(
          argumentName: param.name,
        );
        if (argument == null) {
          if (param.isRequired) {
            throw ApiException(
              message: 'Argument ${param.name} is required',
              traceId: context.traceId,
            );
          }
        }
        value = tryConvertQueryArgumentType(
          actual: argument?.value,
          expectedType: param.reflectedType,
          dateParser: server.dateParser,
        );
      }
      if (param.isPositional) {
        positionalArgs.add(value);
      } else {
        namedArguments[Symbol(param.name)] = value;
      }
    }
    
    return controllerMirror
        .invoke(
          Symbol(instanceMethod.name),
          positionalArgs,
          namedArguments,
        )
        .reflectee;
  }

  @override
  bool operator ==(covariant EndpointMapper other) {
    return other.fullPath == fullPath;
  }

  @override
  int get hashCode {
    return fullPath.hashCode;
  }
}

extension MethodParameterExtension on MethodParameter {
  bool get isBodyParam {
    return _annotations.any((a) => a is FromBody);
  }
}
