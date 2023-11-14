// ignore_for_file: unnecessary_getters_setters


import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/utils/json_utils/value_converters/mongo_id_converter.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

/// Notice that there are some JSON annotations are
/// used here. None of them is required but they help you
/// control the values before they are assigned
/// during a deserialization process. You can implement your
/// own validators extending [JsonValueValidator] class
// @CamelToSnake()
class User {
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

  List<Role>? roles;



  @NameValidator(canBeNull: false)
  String? firstName;

  @NameValidator(canBeNull: false)
  String? lastName;

  String? email;
  String? passwordHash;

  DateTime? createdAt;
  DateTime? updatedAt;

  @override
  bool operator ==(covariant User other) {
    return other._id == _id;
  }

  @override
  int get hashCode {
    return _id.hashCode;
  }
}
