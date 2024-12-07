import 'package:dart_core_orm/dart_core_orm.dart';

class BaseModel {
  @DefaultId()
  int? id;

  @DateColumn(
    defaultValue: DateTimeDefaultValue.currentTimestamp,
    dateType: DateType.timestamp,
  )
  DateTime? createdAt;

  @DateColumn(
    defaultValue: DateTimeDefaultValue.currentTimestamp,
    dateType: DateType.timestamp,
  )
  DateTime? updatedAt;

  @NotNullColumn(defaultValue: false)
  bool? isDeleted;
}
