import 'dart:convert';
import 'dart:io';

import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
import 'package:dart_net_core_api/exports.dart';
import 'package:dart_net_core_api/utils/mirror_utils/extensions.dart';
import 'package:dart_net_core_api/utils/mirror_utils/simple_type_reflector.dart';

part '_documentation_data_container.dart';
part '_documentation_presentation.dart';

/// IMPORTANT!: This is a custom simple documentation format.
/// It's here to simplify working with the API.
/// The package doesn't support OpenAPI format yet, and it's NOT planned
/// to be supported it in the near future.

abstract class APIDocumentationAnnotation {
  const APIDocumentationAnnotation({
    this.description,
    required this.title,
  });

  /// write what your controller is intended to do in free form
  /// this will be displayed in the documentation web page
  final String? description;
  /// [title] will be displayed as a short name in the doc previewer
  final String title;
  
}

/// This group can be used to separate controllers on the UI
class ApiDocumentationGroup {
  final String name;
  final String id;

  const ApiDocumentationGroup({
    required this.name,
    required this.id,
  });
}

class APIControllerDocumentation extends APIDocumentationAnnotation {
  const APIControllerDocumentation({
    super.description,
    required super.title,
    required this.group,
  });

  final ApiDocumentationGroup group;
}

class APIEndpointDocumentation extends APIDocumentationAnnotation {
  const APIEndpointDocumentation({
    required this.responseModels,
    required super.title,
    super.description,
  });

  /// provide a list of objects or types as examples for each
  /// status code
  /// If you want to provide default value in your documentation for
  /// a particular field you can add [APIFieldDocumentation] annotation to it
  /// This will be displayed in the model description section
  ///
  final List<APIResponseExample> responseModels;
}

class APIFieldDocumentation extends APIDocumentationAnnotation {
  const APIFieldDocumentation({
    super.description,
    required super.title,
  });
}

/// This is NOT an annotation and
/// will not be processed if you use it as one
class APIResponseExample {
  final int statusCode;
  final String contentType;
  /// [response] must be a Type in general case 
  /// but it's declared as object for the case of documentation 
  /// generation where we need to wrap it in object
  final Object? response;
  const APIResponseExample({
    required this.statusCode,
    this.contentType = 'application/json',
    this.response,
  });

  bool get isSuccess {
    return statusCode >= 200 && statusCode < 300;
  }
}
