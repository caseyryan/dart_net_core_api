import 'dart:convert';
import 'dart:io';

import 'package:dart_net_core_api/exports.dart';
import 'package:dart_net_core_api/utils/extensions/exports.dart';
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
  });

  /// write what your controller is intended to do in free form
  /// this will be displayed in the documentation web page
  final String? description;
}

class APIControllerDocumentation extends APIDocumentationAnnotation {
  const APIControllerDocumentation({
    super.description,
  });
}

class APIEndpointDocumentation extends APIDocumentationAnnotation {
  const APIEndpointDocumentation({
    required this.responseModels,
    super.description,
  });  

  String toPresentation() {
    /// This condition is here because this is the general error response for any
    /// exception thrown in the scope of the running server instance and even
    /// if you don't throw it explicitly in one of your endpoint processing methods
    /// it will still be possible
    if (responseModels
        .where((e) => e.statusCode == HttpStatus.internalServerError)
        .isEmpty) {
      responseModels.add(
        APIResponseExample(
          statusCode: HttpStatus.internalServerError,
          response: GenericErrorResponse,
        ),
      );
    }
    return '';
  }

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
    this.defaultValueExample,
  });
  final dynamic defaultValueExample;
}

/// This is NOT an annotation and
/// will not be processed if you use it as one
class APIResponseExample {
  final int statusCode;
  final String contentType;
  final Object? response;
  const APIResponseExample({
    required this.statusCode,
    this.contentType = 'application/json',
    this.response,
  });
}
