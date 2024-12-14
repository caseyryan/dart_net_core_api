// ignore_for_file: unnecessary_getters_setters

import 'package:dart_core_orm/dart_core_orm.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

import 'base_mongo_model.dart';

/// Notice that there are some JSON annotations are
/// used here. None of them is required but they help you
/// control the values before they are assigned
/// during a deserialization process. You can implement your
/// own validators extending [JsonValueValidator] class


class User extends BaseModel {
  
  @ORMEnumConverter()
  List<Role>? roles;

  @NameValidator(canBeNull: true)
  @ORMLimitColumn(limit: 60)
  String? firstName;

  @NameValidator(canBeNull: true)
  @ORMLimitColumn(limit: 60)
  String? lastName;

  String getFullName() {
    return '$firstName $lastName';
  }

  @EmailValidator(
    canBeNull: true,
  )
  @ORMUniqueColumn()
  @ORMLimitColumn(limit: 60)
  String? email;

  @PhoneValidator(
    canBeNull: true,
  )
  @ORMUniqueColumn()
  @ORMLimitColumn(limit: 20)
  String? phone;


  @JsonTrimString()
  @NameValidator(canBeNull: true)
  @ORMLimitColumn(limit: 60)
  String? middleName;

  @JsonTrimString()
  @NameValidator(canBeNull: true)
  String? nickName;

  @JsonDateConverter(
    dateFormat: 'yyyy-MM-dd',
  )
  @ORMDateColumn(
    dateType: ORMDateType.date,
    defaultValue: ORMDateTimeDefaultValue.empty,
  )
  DateTime? birthDate;

  @override
  bool operator ==(covariant User other) {
    return other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
