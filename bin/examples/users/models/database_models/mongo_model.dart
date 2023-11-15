

import 'package:dart_net_core_api/utils/json_utils/value_converters/mongo_id_converter.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

/// This type is specially made for mongo compatibility
class MongoModel {
  
  DateTime? createdAt;
  DateTime? updatedAt;

  /// Notice this is a private field but it won't
  /// be serialized / deserialized unless it has
  /// [JsonInclude] annotation
  /// The `dynamic` type is used here because the same model
  /// is used as a database model and a response.
  /// In this case `_id` might be a `String` or and `ObjectId`
  @MongoIdConverter()
  @JsonKey(name: '_id', isIncluded: true)
  dynamic id;
}