part of 'documentation_annotations.dart';

/// This is the class whose instances will finally be converted to
/// JSON to represent documentation
class _ControllerDocumentationPresentation {
  String? controllerName;
  String? description;
  String? title;
  ApiDocumentationGroup? group;
  List<_EndpointDocumentationPresentation>? endpoints;
}

class _AuthorizationDocumentationPresentation {
  List<String>? requiredHeaders;
  List<String>? roles;
}

class _EndpointDocumentationPresentation {
  String? description;
  String? title;
  String? method;
  String? path;
  _AuthorizationDocumentationPresentation? authorization;
  List<_EndpointParameterDocumentationPresentation>? params;
  List<Object>? responseModels;
}

class _EndpointParameterDocumentationPresentation {
  Object? type;
  String? name;
  bool? isBodyParam;
  bool? isRequired;

  _EndpointParameterDocumentationPresentation({
    this.type,
    this.name,
    this.isBodyParam,
    this.isRequired,
  });

  static Object? _toTypePresentation(
    Type? dartType,
    bool isBodyParam,
  ) {
    if (!isBodyParam) {
      return dartType.toString();
    }
    final value = dartType!.toJson(
      includeNullValues: true,
      onBeforeValueSetting: defaultParameterValueSetter,
    );
    return value;
  }

  factory _EndpointParameterDocumentationPresentation.fromMethodParameter(
    MethodParameter value,
  ) {
    final presentation = _EndpointParameterDocumentationPresentation(
      type: _toTypePresentation(
        value.reflectedType,
        value.hasFromBodyAnnotation,
      ),
      name: value.name,
      isBodyParam: value.hasFromBodyAnnotation,
      isRequired: value.isRequired,
    );
    return presentation;
  }
}
