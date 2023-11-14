import 'dart:async';
import 'dart:mirrors';

import 'package:collection/collection.dart';
import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/annotations/socket_controller_annotations.dart';
import 'package:dart_net_core_api/base_services/socket_service/socket_controller.dart';
import 'package:dart_net_core_api/base_services/socket_service/socket_service.dart';
import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/utils/argument_value_type_converter.dart';
import 'package:dart_net_core_api/utils/endpoint_path_parser.dart';
import 'package:dart_net_core_api/utils/extensions/extensions.dart';
import 'package:dart_net_core_api/utils/incoming_path_parser.dart';
import 'package:dart_net_core_api/utils/mirror_utils/extensions.dart';
import 'package:dart_net_core_api/utils/server_utils/any_logger.dart';
import 'package:dart_net_core_api/utils/server_utils/body_reader.dart';
import 'package:dart_net_core_api/utils/server_utils/config/config_parser.dart';
import 'package:logging/logging.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

part 'controller_type_reflector.dart';
part 'socket_controller_type_reflector.dart';

// final ClassMirror _baseApiControllerMirror = reflectType(
//   ApiController,
// ) as ClassMirror;
// final ClassMirror _baseSocketControllerMirror = reflectType(
//   SocketController,
// ) as ClassMirror;

extension ClassMirrorExtension on ClassMirror {
  List<MethodMirror> getConstructors() {
    final constructors = declarations.values
        .where(
          (declare) => declare is MethodMirror && declare.isConstructor,
        )
        .toList();
    return constructors.cast<MethodMirror>().toList();
  }

  bool get isPrimitiveType {
    return _isPrimitiveType(reflectedType);
  }

  List? newTypedListInstance() {
    if (isList) {
      return newInstance(
        Symbol('from'),
        [[]],
      ).reflectee;
    }
    return null;
  }

  Map? newTypedMapInstance() {
    if (isMap) {
      return newInstance(
        Symbol('from'),
        [{}],
      ).reflectee;
    }
    return null;
  }

  bool get isList {
    return qualifiedName == const Symbol('dart.core.List') ||
        qualifiedName == const Symbol('dart.core.GrowableList');
  }

  bool get isMap {
    return qualifiedName == const Symbol('dart.core.Map');
  }

  MethodMirror? get defaultConstructor {
    return getConstructors().firstWhereOrNull((e) => e.parameters.isEmpty);
  }
}

bool _isPrimitiveType(Type type) {
  switch (type) {
    case String:
    case double:
    case num:
    case int:
    case bool:
      return true;
  }
  return false;
}

/// Just a wrapper over mirrors to simplify working with
/// class mirrors, instances and so on
class SimpleTypeReflector {
  late ClassMirror _classMirror;
  late List<dynamic> _annotations;
  late List<Method> constructors;
  late List<Method> methods;
  List<ControllerAnnotation>? _controllerAnnotations;
  // late final bool isApiController;
  // late final bool isSocketController;
  late final bool isPrimitive;

  // bool get isList {
  //   return _classMirror.qualifiedName == const Symbol('dart.core.List');
  // }

  // bool get isMap {
  //   return _classMirror.qualifiedName == const Symbol('dart.core.Map');
  // }

  SimpleTypeReflector(Type fromType) {
    _classMirror = reflectType(fromType) as ClassMirror;
    isPrimitive = _isPrimitiveType(fromType);
    final methodMirrors =
        _classMirror.declarations.values.whereType<MethodMirror>().toList();

    constructors = methodMirrors
        .where((e) => e.isConstructor)
        .map(
          (e) => Method(
            methodMirror: e,
          ),
        )
        .toList();

    methods = methodMirrors.where((e) => !e.isConstructor).map(
      (e) {
        return Method(
          methodMirror: e,
        );
      },
    ).toList();
    _annotations = _classMirror.metadata
        .map(
          (e) => e.reflectee,
        )
        .toList();
    _controllerAnnotations = _annotations
        .whereType<ControllerAnnotation>()
        .cast<ControllerAnnotation>()
        .toList();
  }

  int get numConstructors {
    return constructors.length;
  }

  bool get hasControllerAnnotation {
    return _controllerAnnotations?.isNotEmpty == true;
  }

  bool get hasEndpoints {
    return methods.any((m) => m.hasEndpointAnnotations);
  }

  bool get hasSocketMethods {
    return methods.any((m) => m.hasSocketMethodAnnotations);
  }

  bool hasAnnotationOfType<T>() {
    return _annotations.any((element) => element is T);
  }

  T? tryGetAnnotation<T>() {
    return _annotations.firstWhereOrNull((element) => element is T) as T?;
  }

  List<T> tryGetAnnotations<T>() {
    return _annotations.whereType<T>().toList();
  }

  Map toMap() {
    return {
      'annotations': _annotations.map((e) => e.toString()).toList(),
      'constructors': constructors.map((e) => e.toMap()).toList(),
    };
  }

  bool get hasAnnotations {
    return _annotations.isNotEmpty;
  }
}

/// Just a wrapper to simplify
class SocketMethod extends Method {
  SocketMethod({
    required Method method,
  }) : super(methodMirror: method.methodMirror);

  List<RemoteMethod>? _remoteMethodAnnotations;
  List<RemoteMethod> get remoteMethodAnnotations {
    if (_remoteMethodAnnotations != null) {
      return _remoteMethodAnnotations!;
    }
    _remoteMethodAnnotations = _annotations.whereType<RemoteMethod>().toList();
    if (_remoteMethodAnnotations!.length > 1) {
      throw 'You cannot apply more than one `$RemoteMethod` annotations on a method';
    }
    return _remoteMethodAnnotations!;
  }

  /// At this point we can be sure there is exactly one remote method annotations
  /// so there cannot be a null value and there's no need to check for it
  RemoteMethod get remoteMethod => remoteMethodAnnotations.first;
}

class EndpointMethod extends Method {
  EndpointMethod({
    required Method method,
  }) : super(methodMirror: method.methodMirror);
}

class Method {
  final MethodMirror methodMirror;
  late final List<MethodParameter> parameters;
  late List<dynamic> _annotations;
  late final String name;

  late List<MethodParameter> _positionalParams;
  late List<MethodParameter> _namedParams;

  /// [classInstanceMirror] is an instance mirror of the class to call
  /// the method on
  /// This method can throw different exceptions
  /// They must pro processed
  dynamic call({
    required InstanceMirror classInstanceMirror,
    List<dynamic> positionalArguments = const [],
    Map<String, dynamic> namedArguments = const <String, dynamic>{},
  }) {
    final convertedPositionalArgs = <dynamic>[];
    final convertedNamedArguments = <Symbol, dynamic>{};
    try {
      for (var i = 0; i < _positionalParams.length; i++) {
        final param = _positionalParams[i];
        final expectedType = param.reflectedType;
        final actualValue = positionalArguments[i];
        if (expectedType.isPrimitive) {
          convertedPositionalArgs.add(actualValue);
        } else {
          convertedPositionalArgs.add(expectedType.fromJson(actualValue));
        }
      }

      for (var param in _namedParams) {
        final Object? actualValue = namedArguments[param.name];
        if (actualValue != null) {
          if (actualValue.runtimeType.isPrimitive) {
            convertedNamedArguments[Symbol(param.name)] = actualValue;
          } else {
            final expectedType = param.reflectedType;
            convertedNamedArguments[Symbol(param.name)] =
                expectedType.fromJson(actualValue);
          }
        }
      }
      return classInstanceMirror
          .invoke(
            methodMirror.simpleName,
            convertedPositionalArgs,
            convertedNamedArguments,
          )
          .reflectee;
    } catch (e, s) {
      logGlobal(
        level: Level.SEVERE,
        message: e.toString(),
        stackTrace: s,
      );
    }
  }

  Method({
    required this.methodMirror,
  }) {
    _annotations = methodMirror.metadata.map((e) => e.reflectee).toList();
    name = methodMirror.simpleName.toName();
    final controllerAnnotation = _annotations.whereType<ControllerAnnotation>();
    if (controllerAnnotation.isNotEmpty) {
      throw 'These annotation(s): $controllerAnnotation can only be used on a class. But is/are used on "$name" instance method';
    }

    parameters = methodMirror.parameters
        .map(
          (e) => MethodParameter(parameterMirror: e),
        )
        .toList();
    _namedParams = parameters.where((e) => e.isNamed).toList();
    _positionalParams = parameters.where((e) => e.isPositional).toList();
  }

  bool get hasEndpointAnnotations {
    return _annotations.any((e) => e is EndpointAnnotation);
  }

  bool get hasSocketMethodAnnotations {
    return _annotations.any((e) => e is RemoteMethod);
  }

  int get numParams {
    return parameters.length;
  }

  Map toMap() {
    return {
      'annotations': _annotations.map((e) => e.toString()).toList(),
      'constructorName': name,
      'parameters': parameters.map((e) => e.toMap()).toList(),
    };
  }
}

class MethodParameter {
  final ParameterMirror parameterMirror;
  late final String name;
  late final bool isNamed;
  late final bool isOptional;
  late final Type type;
  late List<dynamic> _annotations;

  bool isSubclassOf<T>() {
    return reflectedType.isSubclassOf<T>();
  }

  bool get isRequired {
    return !isOptional;
  }

  bool get isPositional {
    return !isNamed;
  }

  Type get reflectedType {
    return parameterMirror.type.reflectedType;
  }

  MethodParameter({
    required this.parameterMirror,
  }) {
    isNamed = parameterMirror.isNamed;
    isOptional = parameterMirror.isOptional;
    name = parameterMirror.simpleName.toName();
    // type = parameterMirror.type.reflectedType;
    type = parameterMirror.type.runtimeType;
    _annotations = parameterMirror.metadata.map((e) => e.reflectee).toList();
  }

  Map toMap() {
    return {
      'isNamed': isNamed,
      'isOptional': isOptional,
      'type': type.toString(),
      'name': name,
    };
  }
}
