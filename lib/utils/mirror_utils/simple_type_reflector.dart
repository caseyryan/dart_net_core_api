import 'dart:async';
import 'dart:mirrors';

import 'package:collection/collection.dart';
import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/annotations/json_annotations.dart';
import 'package:dart_net_core_api/exceptions/base_exception.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/utils/argument_value_type_converter.dart';
import 'package:dart_net_core_api/utils/endpoint_path_parser.dart';
import 'package:dart_net_core_api/utils/incoming_path_parser.dart';
import 'package:dart_net_core_api/utils/mirror_utils/extensions.dart';
import 'package:dart_net_core_api/utils/server_utils/body_reader.dart';

part 'controller_type_reflector.dart';
part 'json_type_reflector.dart';

final ClassMirror _baseApiControllerMirror = reflectClass(
  ApiController,
);

/// Just a wrapper over mirrors to simplify working with
/// class mirrors, instances and so on
class SimpleTypeReflector {
  late ClassMirror _classMirror;
  late List<dynamic> _annotations;
  late List<Method> constructors;
  late List<Method> methods;
  List<ControllerAnnotation>? _controllerAnnotations;
  late final bool isApiController;

  SimpleTypeReflector(Type fromType) {
    _classMirror = reflectClass(fromType);
    isApiController = _classMirror.isSubclassOf(
      _baseApiControllerMirror,
    );
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

  bool hasAnnotationOfType<T>() {
    return _annotations.any((element) => element is T);
  }

  T? tryGetAnnotation<T>() {
    return _annotations.firstWhereOrNull((element) => element is T) as T?;
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

class Method {
  final MethodMirror methodMirror;
  late final List<MethodParameter> parameters;
  late List<dynamic> _annotations;
  late final String name;

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
  }

  bool get hasEndpointAnnotations {
    return _annotations.any((e) => e is EndpointAnnotation);
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

  bool get isRequired {
    return !isOptional;
  }

  bool get isPositional {
    return !isNamed;
  }

  MethodParameter({
    required this.parameterMirror,
  }) {
    isNamed = parameterMirror.isNamed;
    isOptional = parameterMirror.isOptional;
    name = parameterMirror.simpleName.toName();
    type = parameterMirror.type.reflectedType;
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
