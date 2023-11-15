// ignore_for_file: unnecessary_getters_setters

import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/utils/json_utils/value_converters/mongo_id_converter.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

import 'base_model.dart';

/// Notice that there are some JSON annotations are
/// used here. None of them is required but they help you
/// control the values before they are assigned
/// during a deserialization process. You can implement your
/// own validators extending [JsonValueValidator] class
// @CamelToSnake()

/// [JsonIncludeParentFields] is used here to also include
/// `id`, `createdAt`, and `updatedAt` from base model to the resulting json
@JsonIncludeParentFields()
class User extends BaseModel {
  /// Notice this is a private field but it won't
  /// be serialized / deserialized unless it has
  /// [JsonInclude] annotation
  /// The `dynamic` type is used here because the same model
  /// is used as a database model and a response.
  /// In this case `_id` might be a `String` or and `ObjectId`
  @JsonInclude()
  @MongoIdConverter()
  dynamic _id;
  dynamic get id => _id;
  set id(dynamic value) {
    _id = value;
  }

  List<Role>? roles;

  @NameValidator(canBeNull: false)
  String? firstName;

  @NameValidator(canBeNull: false)
  String? lastName;

  String? email;
  String? passwordHash;

  @override
  bool operator ==(covariant User other) {
    return other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
