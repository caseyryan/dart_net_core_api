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

    basePath = _fixEndpointPath(
      controllerAnnotations.whereType<BaseApiPath>().firstOrNull?.basePath ?? '',
    );
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
  ApiController? instantiateController({
    required ServiceLocator serviceLocator,
  }) {
    // final paramTypes = _constructor._parameters.map((e) => e.type).toList();

    final positionalArgs = <dynamic>[];
    final Map<Symbol, dynamic> namedArguments = {};
    for (var param in _constructor._parameters) {
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

    final instance = _classMirror.newInstance(
      Symbol(''),
      positionalArgs,
      namedArguments,
    ).reflectee;
    return instance as ApiController;
  }

  EndpointMapper? tryFindEndpointMapper({
    required String path,
    required String method,
  }) {
    return _endpointMappers!.firstWhereOrNull(
      (e) =>
          e.restMethodName == method &&
          e.endpointPathParser.tryMatchPath(
            IncomingPathParser(path),
          ),
    );
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

  @override
  bool operator ==(covariant EndpointMapper other) {
    return other.fullPath == fullPath;
  }

  @override
  int get hashCode {
    return fullPath.hashCode;
  }
}
