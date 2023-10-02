import 'dart:convert';

import 'package:dart_net_core_api/annotations/json_annotations.dart';
import 'package:dart_net_core_api/utils/mirror_utils/simple_type_reflector.dart';

abstract class JsonSerializer {
  /// Allows to convert json keys to whatever you want
  /// for example a snake case or a camel case before serialization
  /// Notice that if you have JsonName attribute applied to a field
  /// it will have the higher priority and will not be converted
  /// using [keyNameConverter]
  final KeyNameConverter? keyNameConverter;
  const JsonSerializer({
    this.keyNameConverter,
  });

  T? fromJson<T>(Map json);

  dynamic toJson(Object? object) {
    return object?.toJson(
      keyNameConverter: keyNameConverter,
    );
  }
  dynamic tryConvertToJsonString(Object? object) {
    final result = toJson(object);
    if (result is Map) {
      return jsonEncode(result);
    }
    return object;
  }
}

/// Serializes and deserializes a response using `dart:mirrors`
/// At the moment the [DefaultJsonSerializer] has a few restrictions:
/// it won't serialize / deserialize
class DefaultJsonSerializer extends JsonSerializer {
  const DefaultJsonSerializer(
    KeyNameConverter? keyNameConverter,
  ) : super(keyNameConverter: keyNameConverter);

  @override
  T? fromJson<T>(Map json) {
    return T.fromJson(json) as T;
  }
}
