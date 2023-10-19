part of 'simple_type_reflector.dart';

class SocketControllerTypeReflector extends SimpleTypeReflector {
  SocketControllerTypeReflector(
    this.controllerType,
  ) : super(controllerType) {
    final isSocketController = _classMirror.isSubclassOf(
      reflectType(SocketController) as ClassMirror,
    );
    assert(
      isSocketController,
      'The provided type: $controllerType does not extend $SocketController. All socket controllers must inherit from $SocketController',
    );
    if (constructors.length > 1) {
      throw 'A $SocketController must have exactly one constructor but $controllerType has ${constructors.length}';
    }

    _authAnnotations = super._annotations.whereType<SocketAuthorization>().toList();
    final socketNamespaceAnnotations = super._annotations.whereType<SocketNamespace>();
    if (socketNamespaceAnnotations.length > 1) {
      throw 'A $SocketController can\'t have more than one $SocketNamespace annotation';
    } else if (socketNamespaceAnnotations.length == 1) {
      _socketNamespace = _fixEndpointPath(socketNamespaceAnnotations.first.path);
    }
  }

  late List<SocketAuthorization> _authAnnotations;

  String _socketNamespace = '/';
  String get socketNamespace => _socketNamespace;

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
    for (var param in _constructor.parameters) {
      final service = serviceLocator(param.reflectedType);
      if (service == null) {
        if (!param.isOptional) {
          throw 'Controller $controllerType requires ${param.type} service but it was not instantiated!';
        }
      }

      /// calling a private method. This is made this way
      /// to avoid reveling it to other instances
      service!.callMethodRegardlessOfVisibility(
        methodName: '_setConfigParser',
        positionalArguments: [
          configParser,
        ],
      );

      if (param.isNamed) {
        namedArguments[Symbol(param.name)] = service;
      } else {
        positionalArgs.add(service);
      }
    }

    _instance = _classMirror
        .newInstance(
          Symbol.empty,
          positionalArgs,
          namedArguments,
        )
        .reflectee;
    return reflect(_instance);
  }

  @override
  bool operator ==(covariant ControllerTypeReflector other) {
    return other.controllerType == controllerType;
  }

  @override
  int get hashCode {
    return controllerType.hashCode;
  }

  final Type controllerType;
}
