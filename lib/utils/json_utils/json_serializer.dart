import 'dart:convert';

import 'package:reflect_buddy/reflect_buddy.dart';

abstract class JsonSerializer {
  /// Allows to convert json keys to whatever you want
  /// for example a snake case or a camel case before serialization
  /// Notice that if you have JsonName attribute applied to a field
  /// it will have the higher priority and will not be converted
  /// using [keyNameConverter]
  final JsonKeyNameConverter? keyNameConverter;
  const JsonSerializer({
    this.keyNameConverter,
  });

  Object? fromJson(
    Map json,
    Type type,
  );

  Object? toJson(Object? object) {
    return object?.toJson(
      keyNameConverter: keyNameConverter,
    );
  }

  Object? tryConvertToJsonString(Object? object) {
    final result = toJson(object);
    if (result is Map) {
      return jsonEncode(result);
    } else if (result is List) {
      return result.map(tryConvertToJsonString).toList();
    }
    return result;
  }
}

/// Serializes and deserializes a response using `dart:mirrors`
/// At the moment the [DefaultJsonSerializer] has a few restrictions:
/// it won't serialize / deserialize
class DefaultJsonSerializer extends JsonSerializer {
  const DefaultJsonSerializer(
    JsonKeyNameConverter? keyNameConverter,
  ) : super(keyNameConverter: keyNameConverter);

  @override
  Object? fromJson(
    Map json,
    Type type,
  ) {
    return type.fromJson(json);
  }
}
