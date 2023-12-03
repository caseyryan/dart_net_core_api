// ignore_for_file: unnecessary_getters_setters

import 'package:dart_net_core_api/server.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

import 'base_mongo_model.dart';

/// Notice that there are some JSON annotations are
/// used here. None of them is required but they help you
/// control the values before they are assigned
/// during a deserialization process. You can implement your
/// own validators extending [JsonValueValidator] class
// @CamelToSnake()

/// [JsonIncludeParentFields] is used here to also include
/// `id`, `createdAt`, and `updatedAt` from base model to the resulting json
@JsonIncludeParentFields()
class User extends BaseMongoModel {
  List<Role>? roles;

  @NameValidator(canBeNull: false)
  String? firstName;

  @NameValidator(canBeNull: false)
  String? lastName;

  @EmailValidator(
    canBeNull: true,
  )
  String? email;

  @PhoneValidator(
    canBeNull: true,
  )
  String? phone;
  @JsonIgnore(ignoreDirections: [
    SerializationDirection.toJson,
  ])
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
