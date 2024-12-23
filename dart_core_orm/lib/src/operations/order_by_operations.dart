import 'package:dart_core_orm/src/exports.dart';

class ORMOrderByOperation {
  ORMOrderByOperation({
    required this.byFieldNames,
    this.direction = ORMOrderByDirection.asc,
  }) : assert(
          byFieldNames.isNotEmpty,
          'You must provide at least one field to order by',
        );

  /// [byFieldNames] is a list of fields to order by
  /// e.g. ['name', 'age'] will order by name and then by age
  /// it must contain at least one field to order by
  /// [direction] is used to specify the direction of the ordering
  final List<String> byFieldNames;
  final ORMOrderByDirection direction;

  String toDatabaseOperation() {
    if (orm.family == ORMDatabaseFamily.postgres) {
      return 'ORDER BY ${byFieldNames.join(', ')} ${direction.toDatabaseOperation()}';
    }
    throw databaseFamilyNotSupportedYet();
  }
}

enum ORMOrderByDirection {
  asc,
  desc;

  String toDatabaseOperation() {
    if (orm.family == ORMDatabaseFamily.postgres) {
      switch (this) {
        case ORMOrderByDirection.asc:
          return 'ASC';
        case ORMOrderByDirection.desc:
          return 'DESC';
      }
    }
    return '';
  }
}
