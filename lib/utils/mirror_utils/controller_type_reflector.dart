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
      final endPointAnnotations = em._annotations.whereType<EndpointAnnotation>();
      if (endPointAnnotations.length > 1) {
        throw 'An endpoint can have only one EndpointAnnotation. But $controllerType -> ${em.name}() has ${endPointAnnotations.length}';
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
      final service = serviceLocator(param.type);
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

  FutureOr<dynamic> tryCallEndpoint({
    required String path,
    required Server server,
    required HttpContext context,
  }) async {
    final InstanceMirror controller = controllerTypeReflection.instantiateController(
      serviceLocator: server.tryGetServiceByType,
    );
    server.updateControllerContext(
      controller: controller.reflectee,
      context: context,
    );

    final incomingPathParser = IncomingPathParser(path);
    final List<dynamic> positionalArgs = [];
    final Map<Symbol, dynamic> namedArguments = {};

    /// by calling these we fill all the pass variables in
    /// the incomingPathParser
    endpointPathParser.tryMatchPath(incomingPathParser);
    for (var param in instanceMethod.parameters) {
      final argument = incomingPathParser.tryFindQueryArgument(
        argumentName: param.name,
      );
      if (argument == null) {
        if (param.isRequired) {
          throw 'Argument ${param.name} is required';
          // throw 'Not all required arguments were provided';
        }
      }
      if (param.isPositional) {
        positionalArgs.add(
          tryConvertArgumentType(
            actual: argument?.value,
            expectedType: param.type,
            dateParser: server.dateParser,
          ),
        );
      } else {
        namedArguments[Symbol(param.name)] = tryConvertArgumentType(
          actual: argument?.value,
          expectedType: param.type,
          dateParser: server.dateParser,
        );
      }
    }
    return controller
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
