import 'package:dart_core_orm/dart_core_orm.dart';

abstract class ORMTableColumnAnnotation {
  const ORMTableColumnAnnotation();

  /// [alternativeParams] sometimes you might not be happy with
  /// what the ORM adds by default to the column description.
  /// In this case you can provide your own params.
  /// They will override all default stuff
  /// e.g. updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
  String getValueForType(
    Type type,
    String fieldName, {
    String? alternativeParams,
  });
  int get order;
}

class ORMForeignKeyColumn extends ORMTableColumnAnnotation {
  /// the hame of the column in other table
  /// that this field is referencing
  /// e.g. you add a foreign key column to a table on an
  /// [author] field and you want to reference the [id] field
  /// of the [Author] table. When making a query it will convert the
  /// field name (`author` in this example, to `author_id` or `authorId`) because
  /// the table is `(Author).toTableName(plural: false) -> author` (NOT pluralized) + `_id` or `Id` if the foreign model
  /// does not require snake case conversion
  final String foreignKey;

  /// [referenceTableType] The type of the table you want to reference. E.g. `Author`
  /// if will automatically convert the object to a foreign key to the `authors` table.
  /// See [foreignKey] field description for details
  final Type referenceTableType;

  const ORMForeignKeyColumn({
    required this.foreignKey,
    required this.referenceTableType,
    this.cascade = true,
  });

  /// [cascade] indicates whether the delete operation
  /// should be cascaded to the referenced table. Basically
  /// it will add ` ON DELETE CASCADE` to the end of the query
  final bool cascade;

  @override
  String getValueForType(
    Type type,
    String fieldName, {
    String? alternativeParams,
  }) {
    assert(alternativeParams == null,
        'alternativeParams is not supported for this annotation');
    final commandOnDelete = cascade ? ' ON DELETE CASCADE' : '';
    return ', FOREIGN KEY ($fieldName) REFERENCES ${referenceTableType.toTableName()}($foreignKey)$commandOnDelete';
  }

  @override
  int get order => 0;
}

class ORMPrimaryKeyColumn extends ORMTableColumnAnnotation {
  const ORMPrimaryKeyColumn();

  @override
  String getValueForType(
    Type type,
    String fieldName, {
    String? alternativeParams,
  }) {
    if (alternativeParams != null) {
      return alternativeParams;
    }
    if (type != int && type != String && type != bool && type != DateTime) {
      return '';
    }
    if (orm.family == ORMDatabaseFamily.postgres) {
      return 'PRIMARY KEY';
    }
    return '';
  }

  @override
  int get order {
    if (orm.family == ORMDatabaseFamily.postgres) {
      return 10;
    }
    return 10;
  }
}

enum ORMDateType {
  date,
  time,
  timestamp,
  timestampWithZone;

  String toDatabaseType(
    ORMDateTimeDefaultValue defaultValue,
  ) {
    if (orm.family == ORMDatabaseFamily.postgres) {
      switch (this) {
        case ORMDateType.date:
          return 'DATE${defaultValue.toDatabaseType()}';
        case ORMDateType.time:
          return 'TIME${defaultValue.toDatabaseType()}';
        case ORMDateType.timestamp:
          return 'TIMESTAMP WITHOUT TIME ZONE${defaultValue.toDatabaseType()}';
        case ORMDateType.timestampWithZone:
          return 'TIMESTAMP WITH TIME ZONE${defaultValue.toDatabaseType()}';
      }
    }
    throw Exception('${orm.family} is not supported');
  }
}

enum ORMIntType {
  integer,
  smallInt,
  bigInt;

  const ORMIntType();

  String toDatabaseType([int? defaultValue]) {
    if (orm.family == ORMDatabaseFamily.postgres) {
      String type = ' BIGINT';
      switch (this) {
        case ORMIntType.integer:
          if (defaultValue != null &&
              (defaultValue < -2147483648 || defaultValue > 2147483647)) {
            type = ' BIGINT ';
          } else {
            type = ' INTEGER ';
          }
          break;
        case ORMIntType.smallInt:
          if (defaultValue != null &&
              (defaultValue < -32768 || defaultValue > 32767)) {
            if ((defaultValue < -2147483648 || defaultValue > 2147483647)) {
              type = ' BIGINT';
            } else {
              type = ' INTEGER';
            }
          } else {
            type = ' SMALLINT';
          }
          break;
        case ORMIntType.bigInt:
          type = ' BIGINT';
          break;
      }
      if (defaultValue != null) {
        return '$type DEFAULT $defaultValue';
      }
      return type;
    }
    throw Exception('${orm.family} is not supported');
  }
}

enum ORMDateTimeDefaultValue {
  currentDate,
  currentTime,
  currentTimestamp,
  localTimestamp,
  empty;

  String toDatabaseType() {
    if (orm.family == ORMDatabaseFamily.postgres) {
      switch (this) {
        case ORMDateTimeDefaultValue.currentDate:
          return ' DEFAULT CURRENT_DATE';
        case ORMDateTimeDefaultValue.currentTime:
          return ' DEFAULT CURRENT_TIME';
        case ORMDateTimeDefaultValue.currentTimestamp:
          return ' DEFAULT CURRENT_TIMESTAMP';
        case ORMDateTimeDefaultValue.localTimestamp:
          return ' DEFAULT LOCALTIMESTAMP';
        case ORMDateTimeDefaultValue.empty:
          return '';
      }
    }
    throw Exception('${orm.family} is not supported');
  }
}

class ORMDateColumn extends ORMTableColumnAnnotation {
  const ORMDateColumn({
    this.defaultValue = ORMDateTimeDefaultValue.empty,
    required this.dateType,
  });
  final ORMDateTimeDefaultValue defaultValue;
  final ORMDateType dateType;

  @override
  String getValueForType(
    Type type,
    String fieldName, {
    String? alternativeParams,
  }) {
    if (type != DateTime) {
      throw Exception(
          '`DateColumn` can be used with `DateTime` type only. [$type] is not supported');
    }
    if (alternativeParams != null) {
      return alternativeParams;
    }
    if (orm.family == ORMDatabaseFamily.postgres) {
      return dateType.toDatabaseType(defaultValue);
    }
    return '';
  }

  @override
  int get order {
    if (orm.family == ORMDatabaseFamily.postgres) {
      return 0;
    }
    return 0;
  }
}

class ORMNotNullColumn extends ORMTableColumnAnnotation {
  const ORMNotNullColumn({
    this.defaultValue,
  });

  final Object? defaultValue;

  @override
  String getValueForType(
    Type type,
    String fieldName, {
    String? alternativeParams,
  }) {
    if (alternativeParams != null) {
      return alternativeParams;
    }
    if (orm.family == ORMDatabaseFamily.postgres) {
      if (type == DateTime) {
        print(
            'You used `NotNullColumn` on a `DateTime` field in $type. To have more flexibility use `DateColumn` anotation instead');
        return ' TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP';
      }
      var defaultsTo = '';
      if (defaultValue != null) {
        if (defaultValue is String) {
          defaultsTo = " DEFAULT '$defaultValue'";
        } else if (defaultValue is bool) {
          defaultsTo = " DEFAULT ${defaultValue.toString().toUpperCase()}";
        } else {
          defaultsTo = ' DEFAULT $defaultValue';
        }
      }
      return 'NOT NULL$defaultsTo';
    }
    return '';
  }

  @override
  int get order {
    if (orm.family == ORMDatabaseFamily.postgres) {
      return 0;
    }
    return 0;
  }
}

class ORMStringColumn extends ORMLimitColumn {
  const ORMStringColumn({
    required super.limit,
  });

  @override
  String getValueForType(
    Type type,
    String fieldName, {
    String? alternativeParams,
  }) {
    if (alternativeParams != null) {
      return alternativeParams;
    }
    if (orm.family == ORMDatabaseFamily.postgres) {
      if (type == String) {
        return 'VARCHAR($limit)';
      }
    }
    return 'TEXT';
  }

  @override
  int get order {
    if (orm.family == ORMDatabaseFamily.postgres) {
      return 1;
    }
    return 0;
  }
}

class ORMIntColumn extends ORMLimitColumn {
  final ORMIntType intType;
  final int? defaultValue;

  const ORMIntColumn({
    super.limit = -1,
    required this.intType,
    this.defaultValue,
  });

  @override
  String getValueForType(
    Type type,
    String fieldName, {
    String? alternativeParams,
  }) {
    if (alternativeParams != null) {
      return alternativeParams;
    }
    final dbType = intType.toDatabaseType(defaultValue);
    if (orm.family == ORMDatabaseFamily.postgres) {
      if (limit != -1) {
        return '$dbType CHECK ($fieldName <= $limit)';
      }
    }
    return dbType;
  }

  @override
  int get order {
    if (orm.family == ORMDatabaseFamily.postgres) {
      return 1;
    }
    return 0;
  }
}

class ORMIndexColumn extends ORMTableColumnAnnotation {
  const ORMIndexColumn();

  @override
  String getValueForType(
    Type type,
    String fieldName, {
    String? alternativeParams,
  }) {
    return '';
  }

  @override
  int get order {
    return 0;
  }
}

/// can limit strings and integers
class ORMLimitColumn extends ORMTableColumnAnnotation {
  final int limit;

  const ORMLimitColumn({
    required this.limit,
  });

  @override
  String getValueForType(
    Type type,
    String fieldName, {
    String? alternativeParams,
  }) {
    if (alternativeParams != null) {
      return alternativeParams;
    }
    if (orm.family == ORMDatabaseFamily.postgres) {
      if (type == String) {
        if (limit == -1) {
          return 'TEXT';
        }
        return 'VARCHAR($limit)';
      }
      if (type == int) {
        if (limit == -1) {
          return 'BIGINT';
        }
        return 'INTEGER CHECK ($fieldName <= $limit)';
      }
    }
    return '';
  }

  @override
  int get order {
    if (orm.family == ORMDatabaseFamily.postgres) {
      return 1;
    }
    return 0;
  }
}

/// This is just a syntactic sugar for the id field
/// What it will do is add 3 other annotations like this
/// instead of itself
// @PrimaryKeyColumn()
// @NotNullColumn()
// @UniqueColumn(autoIncrement: true)
class ORMDefaultId extends ORMTableColumnAnnotation {
  const ORMDefaultId();

  @override
  String getValueForType(
    Type type,
    String fieldName, {
    String? alternativeParams,
  }) {
    assert(alternativeParams == null,
        'alternativeParams is not supported for this annotation');
    return '';
  }

  @override
  int get order {
    return 0;
  }
}

class ORMUniqueColumn extends ORMTableColumnAnnotation {
  final bool autoIncrement;

  const ORMUniqueColumn({
    this.autoIncrement = false,
  });

  @override
  String getValueForType(
    Type type,
    String fieldName, {
    String? alternativeParams,
  }) {
    if (alternativeParams != null) {
      return alternativeParams;
    }
    if (orm.family == ORMDatabaseFamily.postgres) {
      if (autoIncrement && type == int) {
        return 'SERIAL';
      }
      return 'UNIQUE';
    }
    return '';
  }

  @override
  int get order {
    if (orm.family == ORMDatabaseFamily.postgres) {
      return 0;
    }
    return 0;
  }
}
