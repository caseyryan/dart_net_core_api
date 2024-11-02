import 'package:dart_net_core_api/utils/json_utils/value_converters/mongo_id_converter.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

class BaseModel {
  DateTime? createdAt;
  DateTime? updatedAt;
  bool? deleted;

  /// Notice this is a private field but it won't
  /// be serialized / deserialized unless it has
  /// [JsonInclude] annotation
  /// The `dynamic` type is used here because the same model
  /// is used as a database model and a response.
  @MongoIdConverter()
  @JsonKey(
    name: 'id',
    includeDirections: [
      SerializationDirection.fromJson,
      SerializationDirection.toJson,
    ],
    ignoreDirections: [],
  )
  dynamic id;
}
