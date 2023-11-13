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
  @JsonInclude()
  @MongoIdConverter()
  String? _id;
  String? get id => _id;

  List<Role>? roles;


  @NameValidator(canBeNull: false)
  String? firstName;

  @NameValidator(canBeNull: false)
  String? lastName;

  String? email;
  String? passwordHash;
  @JsonIgnore()
  String? refreshToken;

  @override
  bool operator ==(covariant User other) {
    return other._id == _id;
  }

  @override
  int get hashCode {
    return _id.hashCode;
  }
}
