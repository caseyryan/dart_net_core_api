import 'dart:async';

import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/utils/extensions/exports.dart';
import 'package:dart_net_core_api/utils/mirror_utils/simple_type_reflector.dart';

import '../../exports.dart';

/// Add this service to the list of services if you need to generate the API documentation
/// you can also extend this class to process the documentation in your own way

class ApiDocumentationService extends Service {
  List<Type> _controllerTypes = [];
  String? _serverBaseApiPath;

  Object? defaultValueSetter(
    Object? value,
    Type dartType,
    String? fieldName,
  ) {
    if (dartType == String) {
      return 'string';
    }

    return value;
  }

  void setControllerTypes(
    List<Type> controllerTypes,
    String? serverBaseApiPath,
  ) {
    _controllerTypes = controllerTypes;
    _serverBaseApiPath = serverBaseApiPath;
  }

  /// Actual documentation generation
  void _generateDocumentation() {
    for (Type controllerType in _controllerTypes) {
      final simpleTypeReflector = SimpleTypeReflector(controllerType);
      final docContainer = simpleTypeReflector.documentationContainer;
      if (docContainer != null) {
        final map = docContainer.toApiDocumentation(
          _serverBaseApiPath!,
          defaultValueSetter,
        );
        print(map.toFormattedJson());
      }
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
