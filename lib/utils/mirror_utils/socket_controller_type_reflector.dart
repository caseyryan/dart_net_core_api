// ignore_for_file: unused_field

part of 'simple_type_reflector.dart';

class SocketControllerTypeReflector extends SimpleTypeReflector {
  late List<SocketMethod> _socketMethods;

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
    
    _socketMethods = methods
        .where((e) => e.hasSocketMethodAnnotations)
        .map((e) => SocketMethod(method: e))
        .toList();

    

    _authAnnotations = super._annotations.whereType<SocketAuthorization>().toList();

    final socketNamespaceAnnotations = super._annotations.whereType<SocketNamespace>();
    if (socketNamespaceAnnotations.length > 1) {
      throw 'A $SocketController can\'t have more than one $SocketNamespace annotation';
    } else if (socketNamespaceAnnotations.length == 1) {
      _socketNamespace = socketNamespaceAnnotations.first.path.fixEndpointPath();
    }
  }

  late List<SocketAuthorization> _authAnnotations;

  String _socketNamespace = '/';
  String get socketNamespace => _socketNamespace;

  SocketController? _instance;
  SocketController? get instance => _instance;

  Method get _constructor {
    return constructors.first;
  }

  /// Instantiates a controller passing all the necessary
  /// service instance to its constructor if necessary
  InstanceMirror instantiateController({
    required ServiceLocator serviceLocator,
    required ConfigParser configParser,
    required String namespace,
  }) {
    final positionalArgs = <dynamic>[];
    final Map<Symbol, dynamic> namedArguments = {};
    for (MethodParameter param in _constructor.parameters) {
      /// Instantiating a service might require some special actions
      /// So we check if it's a [Service] first
      if (param.isSubclassOf<Service>()) {
        final service = serviceLocator(param.reflectedType);
        if (service == null) {
          if (!param.isOptional) {
            throw 'Controller $controllerType requires ${param.type} service but it was not instantiated!';
          }
        }

        /// calling a private method. This is made this way
        /// to avoid reveling it to other instances
        service!.callMethodByName(
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
    }

    _instance = _classMirror
        .newInstance(
          Symbol.empty,
          positionalArgs,
          namedArguments,
        )
        .reflectee;

    /// Actual initialization of a socket controller
    _instance!.callMethodByName(
      methodName: '_init',
      positionalArguments: [
        _authAnnotations,
        namespace,
        serviceLocator,
        _socketMethods,
      ],
    );

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
