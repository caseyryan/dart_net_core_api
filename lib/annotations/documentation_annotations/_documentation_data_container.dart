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

  /// [defaultValueSetter] will be called before [reflect_buddy] [toJson] method
  /// tries to set a value to a field. In case of documentation generation
  /// the value is always null because [APIDocumentationAnnotation] cannot accept
  /// any non constant values. We provide a response type and this method
  /// converts it to a json map filling all fields with some default values
  Map toApiDocumentation(
    String serverBaseApiPath,
    OnBeforeValueSetting? defaultValueSetter,
  ) {
    final baseApiAnnotation = controllerAnnotations.whereType<BaseApiPath>().firstOrNull;
    final basePath = baseApiAnnotation?.basePath ?? serverBaseApiPath;

    // controllerDocumentationAnnotation

    List<_EndpointDocumentationPresentation> endpointsPresentations = [];
    for (var endpoint in endpoints) {
      endpointsPresentations.add(
        endpoint._toEndpointPresentation(basePath),
      );
    }
    final controllerPresentation = _ControllerDocumentationPresentation()
      ..endpoints = endpointsPresentations
      ..group = controllerDocumentationAnnotation.group

      /// If you don't provide a description there will
      /// still be an empty string at this point
      ..description = controllerDocumentationAnnotation.description
      ..controllerName = controllerTypeName;

    final map = controllerPresentation.toJson(
      tryUseNativeSerializerMethodsIfAny: false,
      includeNullValues: true,
      keyNameConverter: globalDefaultKeyNameConverter,
      onBeforeValueSetting: (value, dartType, keyName) {
        if (value == null) {
          if (dartType == DateTime) {
            return generateRandomDate();
          } else if (dartType == int) {
            return generateRandomInt(0, 999);
          } else if (dartType == double || dartType == num) {
            return generateRandomDouble(0.0, 1000.0);
          } else if (dartType == String) {
            final lowerName = keyName.toLowerCase();
            if (lowerName.contains('name')) {
              if (lowerName.contains('first')) {
                return generateRandomFirstName();
              } else if (lowerName.contains('last')) {
                return generateRandomLastName();
              } else if (lowerName.contains('middle') || lowerName.contains('second')) {
                return generateRandomFirstName();
              }
              return generateRandomFirstName();
            }
            if (lowerName.contains('email')) {
              return generateRandomEmail();
            }
            if (lowerName.contains('phone')) {
              return generateRandomPhone();
            }
            return 'string';
          } else if (dartType == bool) {
            return false;
          }

          if (value == null && !dartType.isPrimitive) {
            return dartType.newTypedInstance();
          }
        } else {
          if (value is DateTime) {
            return generateRandomDate();
          }
        }
        return value;
      },
    ) as Map;

    return map;
  }

  bool get hasEndpoints {
    return endpoints.isNotEmpty;
  }
}

/// accumulates all data to describe an endpoint
/// An instance of this class is used to describe
/// an endpoint in the documentation
/// This is required because Annotation must be const and
/// cannot contain any fields that are mutable
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

  _EndpointDocumentationPresentation _toEndpointPresentation(
    String basePath,
  ) {
    final responseModels = [...apiDocumentationAnnotation.responseModels];

    /// add the default error annotation because
    /// it must be present for
    if (responseModels.where((e) => e.statusCode == HttpStatus.internalServerError).isEmpty) {
      responseModels.add(
        APIResponseExample(
          statusCode: HttpStatus.internalServerError,
          response: GenericJsonResponseWrapper,
        ),
      );
    }
    final paramsPresentation = <_EndpointParameterDocumentationPresentation>[];
    for (var value in [
      ...namedParams,
      ...positionalParams,
    ]) {
      paramsPresentation.add(
        _EndpointParameterDocumentationPresentation.fromMethodParameter(value),
      );
    }

    final presentation = _EndpointDocumentationPresentation()
      ..method = endpointAnnotation.method
      ..description = apiDocumentationAnnotation.description?.replaceAll(RegExp(r'\s+'), ' ').trim()
      ..params = paramsPresentation
      ..responseModels = responseModels
          .map((e) {
            if (e.isSuccess) {
              /// this is done here because by default all success
              /// responses are wrapped in GenericJsonResponseWrapper when .write()
              /// method is called on the response in Server
              final wrappedResponse = GenericJsonResponseWrapper()..data = e.response;
              return APIResponseExample(
                statusCode: e.statusCode,
                contentType: e.contentType,
                response: wrappedResponse,
              );
            } else if (e.response is Type) {
              final type = e.response as Type;
              if (type.isSubclassOf<ApiException>() || type.isSubclassOf<GenericJsonResponseWrapper>()) {
                // print(e.response);
                final value = GenericJsonResponseWrapper()..error = InnerError();
                return APIResponseExample(
                  statusCode: e.statusCode,
                  contentType: e.contentType,
                  response: value,
                );
              }
            }
            return e;
          })
          .nonNulls
          .toList()
      ..path = '$basePath${endpointAnnotation.path}';

    return presentation;
  }
}
