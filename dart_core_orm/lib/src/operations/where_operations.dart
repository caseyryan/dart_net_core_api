/// Where operations
library;

import 'package:dart_core_orm/dart_core_orm.dart';

// TODO: add OR concatination

class ORMWhereEqual extends ORMWhereOperation {
  ORMWhereEqual({
    required super.key,
    required super.value,
    super.nextJoiner = ORMJoiner.and,
  }) : super(
          operation: ORMWhereOperationType.equal,
        );
}

class ORMWhereNotEqual extends ORMWhereOperation {
  ORMWhereNotEqual({
    required super.key,
    required super.value,
    super.nextJoiner = ORMJoiner.and,
  }) : super(
          operation: ORMWhereOperationType.notEqual,
        );
}

class ORMWhereGreaterThan extends ORMWhereOperation {
  ORMWhereGreaterThan({
    required super.key,
    required super.value,
    super.nextJoiner = ORMJoiner.and,
  }) : super(
          operation: ORMWhereOperationType.greater,
        );
}

class ORMWhereLessThan extends ORMWhereOperation {
  ORMWhereLessThan({
    required super.key,
    required super.value,
    super.nextJoiner = ORMJoiner.and,
  }) : super(
          operation: ORMWhereOperationType.less,
        );
}

class ORMWhereGreaterThanOrEqual extends ORMWhereOperation {
  ORMWhereGreaterThanOrEqual({
    required super.key,
    required super.value,
    super.nextJoiner = ORMJoiner.and,
  }) : super(
          operation: ORMWhereOperationType.greaterOrEqual,
        );
}

class ORMWhereLessThanOrEqual extends ORMWhereOperation {
  ORMWhereLessThanOrEqual({
    required super.key,
    required super.value,
    super.nextJoiner = ORMJoiner.and,
  }) : super(
          operation: ORMWhereOperationType.lessOrEqual,
        );
}

class ORMWhereInList extends ORMWhereOperation {
  ORMWhereInList({
    required super.key,
    required List<Object?> value,
    super.nextJoiner = ORMJoiner.and,
  }) : super(
          operation: ORMWhereOperationType.inList,
          value: value,
        );
}

class ORMWhereBetween extends ORMWhereOperation {
  ORMWhereBetween({
    required super.key,
    required List<Object> value,
  })  : assert(
          value.length == 2,
          'Between operation requires two values',
        ),
        super(
          operation: ORMWhereOperationType.between,
          value: value,
          nextJoiner: ORMJoiner.and,
        );
}

class ORMWhereLike extends ORMWhereOperation {
  ORMWhereLike({
    required super.key,
    required super.value,
    super.nextJoiner = ORMJoiner.and,
  }) : super(
          operation: ORMWhereOperationType.like,
        );
}

abstract class ORMWhereOperation {
  ORMWhereOperation({
    required String key,
    this.value,
    required this.operation,
    required this.nextJoiner,
  }) : key = key.wrapInDoubleQuotesIfNeeded();

  /// column name
  final String key;

  /// the value to compare with
  final Object? value;
  final ORMWhereOperationType operation;

  /// [nextJoiner] is used to specify how to join the operations
  /// e.g. if you want to use OR instead of AND
  /// it will have effect if you provide more than one operation
  final ORMJoiner nextJoiner;

  String toOperation([
    String aliasPrefix = '',
  ]) {
    if (orm.family == ORMDatabaseFamily.postgres) {
      Object? valueRepresentation;
      final columnName = aliasPrefix.isEmpty ? key : '$aliasPrefix.$key';
      /// Som operations like IS NULL, IS NOT NULL
      /// don't require a value to compare with
      if (operation.canUseValue) {
        if (value is List) {
          final list = value as List;
          if (operation == ORMWhereOperationType.between) {
            return '$columnName ${operation.toDatabaseWhereOperation()} ${list.first} AND ${list.last}';
          }
          valueRepresentation = list.map((e) {
            // if (e is String) {
            //   return e.sanitize();
            // }
            return (e as Object).tryConvertValueToDatabaseCompatible();
          }).join(',');
          valueRepresentation = '($valueRepresentation)';
        } else {
          valueRepresentation = (value as Object).tryConvertValueToDatabaseCompatible();
        }
      } else {
        valueRepresentation = '';
      }
      return '$columnName ${operation.toDatabaseWhereOperation()} $valueRepresentation'.trim();
    }
    throw databaseFamilyNotSupportedYet();
  }
}

enum ORMJoiner {
  and,
  or;

  const ORMJoiner();

  String toDatabaseOperation() {
    if (orm.family == ORMDatabaseFamily.postgres) {
      switch (this) {
        case ORMJoiner.and:
          return 'AND';
        case ORMJoiner.or:
          return 'OR';
      }
    }
    return '';
  }
}

enum ORMWhereOperationType {
  equal,
  notEqual,
  less,
  greater,
  lessOrEqual,
  greaterOrEqual,
  inList,
  isNull(false),
  isNotNull(false),
  between,
  all,
  like;

  final bool canUseValue;

  String toDatabaseWhereOperation() {
    if (orm.family == ORMDatabaseFamily.postgres) {
      switch (this) {
        case ORMWhereOperationType.all:
          return '*';
        case ORMWhereOperationType.equal:
          return '=';
        case ORMWhereOperationType.notEqual:
          return '!=';
        case ORMWhereOperationType.less:
          return '<';
        case ORMWhereOperationType.greater:
          return '>';
        case ORMWhereOperationType.lessOrEqual:
          return '<=';
        case ORMWhereOperationType.greaterOrEqual:
          return '>=';
        case ORMWhereOperationType.like:
          return 'LIKE';
        case ORMWhereOperationType.between:
          return 'BETWEEN';
        case ORMWhereOperationType.inList:
          return 'IN';
        case ORMWhereOperationType.isNull:
          return 'IS NULL';
        case ORMWhereOperationType.isNotNull:
          return 'IS NOT NULL';
      }
    }
    throw databaseFamilyNotSupportedYet();
  }

  const ORMWhereOperationType([
    this.canUseValue = true,
  ]);
}
