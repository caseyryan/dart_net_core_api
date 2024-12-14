import 'package:dart_core_orm/dart_core_orm.dart';

/// a set of field that are supposed to be in every model in this database
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
