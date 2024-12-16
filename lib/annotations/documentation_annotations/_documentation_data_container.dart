part of 'documentation_annotations.dart';

class APIControllerDocumentationContainer {

  APIControllerDocumentationContainer({
    required this.endpoints,
    required this.controllerAnnotation,
  });
  final APIControllerDocumentation controllerAnnotation;
  final List<EndpointDocumentationContainer> endpoints;

  String toPresentation() {

    return '';
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

  String toPresentation() {
    return '';
  }

}
