import 'package:dart_core_orm/src/annotations/table_column_annotations.dart';
import 'package:dart_core_orm/src/converters/json_value_converters.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

/// The annotation comes from the [reflect_buddy] package
/// it is used to convert all field names to snake case
/// e.g. enginePower will be converted to engine_power and the
/// database column name will also be snake cased
@CamelToSnake()
class Car {
  @ORMPrimaryKeyColumn()
  @ORMNotNullColumn()
  @ORMUniqueColumn(autoIncrement: true)
  int? id;

  @ORMLimitColumn(limit: 20)
  String? manufacturer;

  /// don't let the car be more powerful than 300 horsepower)
  @ORMLimitColumn(limit: 300)
  int? enginePower;
}

@CamelToSnake()
class Book {
  @ORMPrimaryKeyColumn()
  @ORMNotNullColumn()
  @ORMUniqueColumn(autoIncrement: true)
  int? id;

  String? title;

  /// This foreign key will actually transform the field in the database
  /// in this case [author] will be transformed into [author_id]
  /// (by using (Author).toTableName(plural: false) + '_${fieldName}')
  /// IMPORTANT: any foreign keys inside a model automatically transform
  /// a simple query to a transaction (where it's possible, not any database supports it)
  /// to make sure everything is inserted correctly
  /// before inserting the main model
  @ORMForeignKeyColumn(
    foreignKey: 'id', // turns `author` to `author_id` in this case
    referenceTableType: Author,
    cascade: true,
  )
  Author? author;
}

@CamelToSnake()
class Author {
  @ORMPrimaryKeyColumn()
  @ORMNotNullColumn()
  @ORMUniqueColumn(autoIncrement: true)
  int? id;

  String? firstName;
  String? lastName;
}

class Reader {
  @ORMDefaultId()
  int? id;

  @ORMNotNullColumn(defaultValue: 'John Doe')
  String? fullName;
}

enum Role {
  guest(0),
  user(1),
  editor(3),
  moderator(100),
  admin(200),
  owner(300);

  const Role(this.priority);
  final int priority;
}

@JsonIncludeParentFields()
class User extends BaseModel {

  /// enum converter is important here, because 
  /// PostgreSQL Dart driver doesn't understand ARRAY[]
  /// and returns it as UndecodedBytes
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
  @ORMIndexColumn()
  String? phone;

  // @JsonIgnore(ignoreDirections: [
  //   SerializationDirection.toJson,
  // ])
  @ORMLimitColumn(limit: 46)
  String? passwordHash;

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

class BaseModel {
  @ORMDefaultId()
  int? id;

  @ORMDateColumn(
    defaultValue: ORMDateTimeDefaultValue.currentTimestamp,
    dateType: ORMDateType.timestamp,
  )
  DateTime? createdAt;

  @ORMDateColumn(
    defaultValue: ORMDateTimeDefaultValue.currentTimestamp,
    dateType: ORMDateType.timestamp,
  )
  DateTime? updatedAt;

  @ORMNotNullColumn(defaultValue: false)
  bool? isDeleted;
}
