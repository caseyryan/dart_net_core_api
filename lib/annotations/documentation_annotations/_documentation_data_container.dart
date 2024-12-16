part of 'documentation_annotations.dart';

class APIControllerDocumentationContainer {
  APIControllerDocumentationContainer({
    required this.endpoints,
    required this.controllerDocumentationAnnotation,
    required this.controllerAnnotations,
    required this.controllerTypeName,
  });
  final APIControllerDocumentation controllerDocumentationAnnotation;
  final List<EndpointDocumentationContainer> endpoints;
  final List<ControllerAnnotation> controllerAnnotations;
  final String controllerTypeName;

  Map toPresentation(
    String serverBaseApiPath,
  ) {
    final baseApiAnnotation =
        controllerAnnotations.whereType<BaseApiPath>().firstOrNull;
    final basePath = baseApiAnnotation?.basePath ?? serverBaseApiPath;

    List<_EndpointDocumentationPresentation> endpointsPresentations = [];
    for (var endpoint in endpoints) {
      endpointsPresentations.add(
        endpoint._toPresentation(basePath),
      );
    }
    final controllerPresentation = _ControllerDocumentationPresentation()
      ..endpoints = endpointsPresentations
      ..controllerName = controllerTypeName;

    return controllerPresentation.toJson(
      tryUseNativeSerializerMethodsIfAny: false,
    ) as Map;
  }

  bool get hasEndpoints {
    return endpoints.isNotEmpty;
  }
}

/// accumelates all data to describe an endpoint
/// An instance of this calss is used to describe
/// an endpoint in the documentation
class EndpointDocumentationContainer {
  EndpointDocumentationContainer({
    required this.endpointAnnotation,
    required this.apiDocumentationAnnotation,
    required this.positionalParams,
    required this.namedParams,
  });

  final EndpointAnnotation endpointAnnotation;
  final APIEndpointDocumentation apiDocumentationAnnotation;
  final List<MethodParameter> positionalParams;
  final List<MethodParameter> namedParams;

  _EndpointDocumentationPresentation _toPresentation(
    String basePath,
  ) {
    final presentation = _EndpointDocumentationPresentation()
    ..method = endpointAnnotation.method
    ..path = '$basePath${endpointAnnotation.path}';

    return presentation;
  }
}
