/// IMPORTANT!: This is a custom simple documentation format.
/// It's here to simplify working with the API.
/// The package doesn't support OpenAPI format yet, and it's NOT planned
/// to be supported it in the near future.

abstract class DocumentationAnnotation {
  const DocumentationAnnotation({
    this.description,
  });

  /// write what your controller is intended to do in free form
  /// this will be displayed in the documentation web page
  final String? description;
}

class ControllerDocumentation extends DocumentationAnnotation {
  const ControllerDocumentation({
    super.description,
  });
}

class EndpointDocumentation extends DocumentationAnnotation {
  const EndpointDocumentation({
    required this.examples,
    super.description,
  });

  /// provide a list of objects or types as examples for each
  /// status code
  /// If you want to provide default value in your documentation for
  /// a particular field you can add [FieldDocumentation] annotation to it
  /// This will be displayed in the model description section
  /*
  @Documentation(
    examples: [
      OpenApiResponseExample(
        statusCode: 200,
        response: Car
      ),
      OpenApiResponseExample(
        statusCode: 404,
        response NotFoundException,
      ),
    ],
  )
  */
  /// In this case the car object will be serialized with all the examples
  /// But you may also provide a type instead, in this case the default
  /// values will be generated.
  /// IMPORTANT! If you have multiple places where the same type is used
  /// but in some case you provide an instance and in other case you provide
  /// a type, the INSTANCE will be used in all places where it's used by default
  /// because it provides a more accurate representation of the data
  final List<OpenApiResponseExample> examples;
}

class FieldDocumentation extends DocumentationAnnotation {
  const FieldDocumentation({
    super.description,
    this.defaultValueExample,
  });
  final dynamic defaultValueExample;
}

/// This is NOT an annotation and
/// will not be processed if you use it as one
class OpenApiResponseExample {
  final int statusCode;
  final String contentType;
  final Object? response;
  const OpenApiResponseExample({
    required this.statusCode,
    this.contentType = 'application/json',
    this.response,
  });
}
