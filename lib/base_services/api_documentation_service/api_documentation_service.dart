import 'dart:async';

import 'package:dart_net_core_api/utils/mirror_utils/simple_type_reflector.dart';

import '../../exports.dart';

/// Add this service to the list of services if you need to generate the API documentation
/// you can also extend this class to process the documentation in your own way

class ApiDocumentationService extends Service {

  List<Type> _controllerTypes = [];

  void setControllerTypes(
    List<Type> controllerTypes,
  ) {
    _controllerTypes = controllerTypes;
  }

  void _generateDocumentation() {
    for (Type controllerType in _controllerTypes) {
      final simpleTypeReflector = SimpleTypeReflector(controllerType);
    }
  }

  @override
  FutureOr dispose() {
    throw 'This service must not be added as a singleton';
  }

  @override
  FutureOr onReady() {
    _generateDocumentation();
  }
}
