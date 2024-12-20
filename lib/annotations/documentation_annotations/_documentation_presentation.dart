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

class _EndpointDocumentationPresentation {
  String? description;
  String? title;
  String? method;
  String? path;
  List<_EndpointParameterDocumentationPresentation>? params;
  List<Object>? responseModels;
}

class _EndpointParameterDocumentationPresentation {
  Object? type;
  String? name;
  bool? isBodyParam;
  bool? isRequired;
  // String? description;
  // int? min;
  // int? max;

  _EndpointParameterDocumentationPresentation({
    this.type,
    this.name,
    this.isBodyParam,
    this.isRequired,
    // this.description,
    // this.min,
    // this.max,
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
    // return JsonEncoder.withIndent("  ").convert(value);
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
