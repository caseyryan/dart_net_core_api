import 'package:dart_core_orm/dart_core_orm.dart';

import 'base_model.dart';

class Password extends BaseModel {

  @ORMUniqueColumn()
  int? userId;

  @ORMLimitColumn(limit: 46)
  String? passwordHash;
}
