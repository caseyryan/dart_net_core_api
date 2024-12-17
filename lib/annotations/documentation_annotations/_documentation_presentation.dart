part of 'documentation_annotations.dart';

/// This is the class whose instances will finally be converted to 
/// JSON to represent documentation
class _ControllerDocumentationPresentation {
  String? controllerName;
  List<_EndpointDocumentationPresentation>? endpoints;
}

class _EndpointDocumentationPresentation {
  String? method;
  String? path;
  List<APIResponseExample>? responseModels;

}
