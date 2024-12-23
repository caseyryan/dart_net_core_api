// ignore_for_file: depend_on_referenced_packages

import 'dart:math';
import 'dart:mirrors';

import 'package:collection/collection.dart';
import 'package:dart_core_orm/dart_core_orm.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

part '_support_types.dart';

extension TypeExtension on Type {
  bool get isList {
    /// not the most reliable way to check if a type is a list
    /// but for the sake of this ORM it's enough.
    return toString().contains('List');
  }

  ChainedQuery _toChainedQuery() {
    final query = this is ChainedQuery ? this as ChainedQuery : ChainedQuery()
      ..type = this;
    return query;
  }

  String toDatabaseType(
    List<ORMTableColumnAnnotation> columnAnnotations,
    String fieldName,
  ) {
    if (this == String) {
      if (orm.family == ORMDatabaseFamily.postgres) {
        if (columnAnnotations.isNotEmpty) {
          final limitAnnotation = columnAnnotations.lastWhereOrNull(
            (e) => e is ORMLimitColumn,
          );
          if (limitAnnotation != null) {
            return limitAnnotation.getValueForType(this, fieldName);
          }
        }
        return '';
      }
    } else if (this == int) {
      if (orm.family == ORMDatabaseFamily.postgres) {
        final limitAnnotation = columnAnnotations.lastWhereOrNull(
          (e) => e is ORMLimitColumn,
        );
        if (limitAnnotation != null) {
          return limitAnnotation.getValueForType(this, fieldName);
        }
        final uniqueConstraint = columnAnnotations.whereType<ORMUniqueColumn>().firstOrNull;
        if (uniqueConstraint != null) {
          /// for SERIAL type we don't need any of these
          columnAnnotations.removeWhere((e) => e is ORMNotNullColumn);
          if (uniqueConstraint.autoIncrement == true) {
            /// uniqueConstraint?.autoIncrement adds SERIAL pseudo type
            /// that is automatically creating an INTEGER wo we don't need to return integer
            /// here
            return '';
          }
        }
        return 'INTEGER';
      }
    } else if (this == bool) {
      if (orm.family == ORMDatabaseFamily.postgres) {
        return 'BOOLEAN';
      }
    } else if (this == double || this == num) {
      if (orm.family == ORMDatabaseFamily.postgres) {
        return 'DECIMAL';
      }
    } else if (this == DateTime) {
      if (orm.family == ORMDatabaseFamily.postgres) {
        final dateColumnAnnotation = columnAnnotations.whereType<ORMDateColumn>().firstOrNull;
        if (dateColumnAnnotation != null) {
          return '';
        }
        return 'TIMESTAMP WITH TIME ZONE';
      }
    } else if (isList) {
      if (orm.family == ORMDatabaseFamily.postgres) {
        final reflection = reflectType(this);
        final reflectionClassMirror = (reflection as ClassMirror);
        if (reflectionClassMirror.isGeneric) {
          final genericType = reflectionClassMirror.typeArguments.first.reflectedType;
          if (genericType == String) {
            return 'TEXT[]';
          } else if (genericType == int) {
            return 'INTEGER[]';
          } else if (genericType == bool) {
            return 'BOOLEAN[]';
          } else if (genericType == DateTime) {
            return 'TIMESTAMP WITH TIME ZONE[]';
          } else if (genericType == double || genericType == num) {
            return 'DECIMAL[]';
          } else {
            final reflectedClass = reflectClass(genericType);
            if (reflectedClass.isEnum) {
              return 'TEXT[]';
            }
          }
        }
      }
    }
    return '';
  }

  /// [dryRun] is used to only show the query itself not actually executing it
  /// [ifExists] is used to check if the table exists before dropping it
  /// to avoid error in case the table does not exist
  /// [cascade] this will automatically drop any dependent objects
  /// such as foreign key constraints.
  Future dropTable({
    bool dryRun = false,
    bool ifExists = false,
    bool cascade = false,
  }) async {
    final query = _toChainedQuery();
    final tableName = toTableName();
    if (orm.family == ORMDatabaseFamily.postgres) {
      if (ifExists) {
        query.add('DROP TABLE IF EXISTS $tableName');
      } else {
        query.add('DROP TABLE $tableName');
      }
      if (cascade) {
        query.add('CASCADE');
      }
      if (!dryRun) {
        await query.execute();
      } else {
        query.printQuery();
      }
    }
  }

  Map<String, String> toColumnKeys() {
    final objectType = this.fromJson({});
    final convertedKeys = <String, String>{};
    objectType!.toJson(
      includeNullValues: true,
      onKeyConversion: (
        ConvertedKey keyConversionResult,
      ) {
        convertedKeys[keyConversionResult.oldKey] = keyConversionResult.newKey;
      },
    );
    return convertedKeys;
  }

  /// [oldTableName] must be passed only in case
  /// the name has also changed. If you didn't rename the class
  /// and didn't change the column naming policy, leave it null
  Future alterTable({
    bool dryRun = false,
    String? oldTableName,
  }) async {
    if (orm.family == ORMDatabaseFamily.postgres) {
      /// for some reason if a table was created with double quotes
      /// it won't work with this request
      final tableName = (oldTableName ?? toTableName()).stripWrappingDoubleQuotes();

      final simpleScheme = await orm.executeSimpleQuery(
        query: '''
          SELECT column_name, data_type
          FROM information_schema.columns
          WHERE table_name = '$tableName';
        ''',
      );
      if (simpleScheme is List && simpleScheme.isNotEmpty) {
        final scheme = _SimpleTableScheme.fromPostgresRawList(
          newTableName: oldTableName != null ? tableName : null,
          tableName: oldTableName ?? tableName,
          value: simpleScheme,
        );
        final alterTableQuery = scheme.toAlterTableQuery(this);
        print(alterTableQuery);
      }
    }
  }

  List<FieldDescription> describeFields() {
    final classMirror = reflectType(this) as ClassMirror;
    return classMirror.getFieldsDescriptions(
      this,
    );
  }

  /// Creates indices for all fields that have [ORMIndexColumn] or [ORMUniqueColumn] annotations
  Future<bool> createIndices({
    bool dryRun = false,
  }) async {
    if (orm.family == ORMDatabaseFamily.postgres) {
      final tableName = toTableName();
      final List<FieldDescription> fields = describeFields().where((e) => e.isIndex).toList();
      if (fields.isEmpty) {
        return true;
      }
      List<String> createIndexQueries = [
        'BEGIN;',
      ];
      for (var field in fields) {
        final fieldName = field.fieldName;
        final indexName = 'idx_$fieldName';
        createIndexQueries.add('  CREATE INDEX IF NOT EXISTS $indexName ON $tableName ($fieldName);');
      }
      createIndexQueries.add('COMMIT;');
      final query = createIndexQueries.join('\n');
      final result = await orm.executeSimpleQuery(
        query: query,
        dryRun: dryRun,
      );
      if (result is List && result.isEmpty) {
        return true;
      }
      if (result is OrmError) {
        throw result;
      }
      return true;
    }
    return false;
  }

  /// [dryRun] is used to only show the query itself not actually
  /// executing it
  /// [createTriggerCode] allows you to create some triggers for a table
  /// if necessary. To know the table creation query use dryRun first
  Future<bool> createTable({
    bool dryRun = false,
    bool ifNotExists = true,
    String? createTriggerCode,
  }) async {
    final query = _toChainedQuery();
    final tableName = toTableName();
    final typeMirror = reflectType(query.type!);
    final classMirror = typeMirror as ClassMirror;
    if (orm.family == ORMDatabaseFamily.postgres) {
      query.add('CREATE TABLE');
      if (ifNotExists) {
        query.add('IF NOT EXISTS');
      }
      query.add(tableName);
      query.add('(');

      final List<FieldDescription> fieldDescriptions = classMirror.getFieldsDescriptions(
        query.type!,
      );

      /// just a small hack to put id field at the beginning
      final idIndex = fieldDescriptions.indexWhere((e) => e.fieldName == 'id');
      if (idIndex != -1) {
        fieldDescriptions.insert(0, fieldDescriptions.removeAt(idIndex));
      }

      query.add(fieldDescriptions.join(', '));
      createTriggerCode ??= createUpdatedAtTriggerCode(
        tableName: toTableName(),
        columnName:
            globalDefaultKeyNameConverter == SnakeToCamel && orm.useCaseSensitiveNames ? "'updatedAt'" : 'updated_at',
      );

      bool createTrigger = createTriggerCode != null;
      query.add(')${createTrigger ? ';\n' : ''}');
      if (createTrigger) {
        query.add(createTriggerCode);
      }
      if (!dryRun) {
        final result = await query.execute(
          dryRun: dryRun,
          returnResult: true,
        );
        return result == null || (result is List && result.isEmpty);
      } else {
        query.printQuery();
      }
      return false;
    }
    throw databaseFamilyNotSupportedYet();
  }

  /// [update] is an instance of your model with the changed
  /// fields you want to update
  /// e.g. you want to update a Car record and update the manufacturer:
  /// you create an instance of Car and set the manufacturer field
  /// and after that you write a where clause to specify which record
  /// to update
  /// like this:
  /*

    final updatedInstance = Car() 
     ..manufacturer = 'BYD Tang';
      (Car).update(updatedInstance).where([
        Equal(
          key: 'id',
          value: 7,
        ),
      ]).execute();
  
   */
  /// This will update the record with the id of 7
  /// and set the manufacturer to 'BYD Tang'

  ChainedQuery update<T>(T update) {
    final query = _toChainedQuery();
    final tableName = toTableName();
    if (orm.family == ORMDatabaseFamily.postgres) {
      query.add('UPDATE $tableName');
      final json = (update as Object).toJson(
        includeNullValues: false,
      ) as Map;
      query.add('SET');
      query.add(json.entries.map(
        (entry) {
          return '${entry.key} = ${(entry.value as Object).tryConvertValueToDatabaseCompatible()}';
        },
      ).join(', '));
    }
    return query;
  }

  ChainedQuery insertMany<T>(
    List<T> inserts, {
    ConflictResolution conflictResolution = ConflictResolution.error,
  }) {
    final query = _toChainedQuery();
    final tableName = toTableName();
    final values = StringBuffer();
    String? updateQuery;
    if (orm.family == ORMDatabaseFamily.postgres) {
      bool hasForeignKeys = false;
      for (var i = 0; i < inserts.length; i++) {
        final item = inserts[i] as Object;
        final isLast = i == inserts.length - 1;

        final foreignKeyObjects = item.getForeignKeyObjects();
        hasForeignKeys = foreignKeyObjects.isNotEmpty;
        if (hasForeignKeys) {
          /// Create a transaction for foreign keys
          final tempQueries = <String>['BEGIN;'];
          tempQueries.add('WITH upsert AS ( ');
          for (var fko in foreignKeyObjects) {
            final fkoQuery = fko.object.insert(
              conflictResolution: ConflictResolution.ignore,
              withUpsert: true,
            );
            tempQueries.add(
              fkoQuery.toQueryString(
                /// semicolon not required because it's a common table expression
                /// before the INSERT query
                addSemicolon: false,
              ),
            );
          }
          final InsertQueries? insertQueries = item.toInsertQueries(
            item,
            foreignKeyObjects: foreignKeyObjects,
            withUpsert: true,
          );

          /// closes WITH upsert AS (
          tempQueries.add(')');
          tempQueries.add(
            'INSERT INTO $tableName ${insertQueries!.keys} VALUES ${insertQueries.values}',
          );
          updateQuery = insertQueries.onConflictQueries.first;
          if (updateQuery.isNotEmpty == true) {
            tempQueries.add(updateQuery);
          }
          tempQueries.add(';');
          tempQueries.add('COMMIT');
          query._parts.clear();
          query._parts.addAll(tempQueries);
        } else {
          final insertQueries = item.toInsertQueries(
            item,
          );
          if (insertQueries != null) {
            if (i == 0) {
              //   updateQuery = insertQueries.onConflicsQueries.first;
              values.write(insertQueries.keys);
              values.write(' VALUES ');
            }
            values.write(insertQueries.values);
            if (!isLast) {
              values.write(', ');
            }
          }
        }
      }
      if (!hasForeignKeys) {
        query.add('INSERT INTO $tableName');
        query.add(values.toString());
        if (updateQuery?.isNotEmpty == true) {
          query.add(updateQuery!);
        }
      }
    }

    return query;
  }

  ChainedQuery select([
    List<String>? paramsNames,
  ]) {
    final query = _toChainedQuery();
    final tableName = toTableName();
    final alias = tableName.toAlias();
    if (query.tableAliasPrefix.isEmpty) {
      query.tableAliasPrefix = alias;
    }
    if (orm.family == ORMDatabaseFamily.postgres) {

      query.add('SELECT');
      if (paramsNames?.isNotEmpty != true) {
        query.add('$alias.*');
      } else {
        query.add(paramsNames!.map((e) => '$alias.$e').join(', '));
      }
      query.add('FROM $tableName AS $alias');
    }
    return query;
  }

  ChainedQuery delete() {
    final query = _toChainedQuery();
    final tableName = toTableName();
    if (orm.family == ORMDatabaseFamily.postgres) {
      query.add('DELETE FROM $tableName');
    }
    return query;
  }

  bool isSubclassOf<T>() {
    final classMirror = reflectType(this) as ClassMirror;
    return classMirror.isSubclassOf(reflectType(T) as ClassMirror);
  }

  /// [plural] by default the table names are pluralized
  /// e.g Author -> authors
  String toTableName({
    bool plural = true,
  }) {
    final typeMirror = reflectType(this);
    final metadata = typeMirror.metadata;

    final classAnnotations = metadata.where(
      (e) {
        return e.reflectee.runtimeType.isSubclassOf<ClassAnnotation>();
      },
    ).toList();
    final ending = plural ? 's' : '';
    final name = (classAnnotations.lastOrNull?.reflectee as TableName?)?.name ??
        '${typeMirror.simpleName.toName().camelToSnake()}$ending';
    return name.wrapInDoubleQuotesIfNeeded();
  }
}

enum ConflictResolution {
  ignore,
  update,
  error,
}

class ChainedQuery {
  Type? type;
  String tableAliasPrefix = '';

  static const String delimiter = '|||';

  final List<String> _parts = [];

  void add(String part) {
    _parts.add(part);
  }

  void prepend(String part) {
    _parts.insert(0, part);
  }

  String get queryType {
    if (_parts.isNotEmpty) {
      final first = _parts.first;
      if (first.contains('SELECT')) {
        return 'SELECT';
      }
      if (first.contains('INSERT')) {
        return 'INSERT';
      }
      if (first.contains('UPDATE')) {
        return 'UPDATE';
      }
      if (first.contains('DELETE')) {
        return 'DELETE';
      }
      if (first.contains('CREATE TABLE')) {
        return 'CREATE TABLE';
      }
    }
    return '';
  }

  /// With some type of conflict resolutions
  /// RETURNING might already be added to the query
  /// previously so adding it one more time will result in an error
  bool get _canAddReturningStatementAtTheEnd {
    if (toQueryString().contains('RETURNING')) {
      return false;
    }
    switch (queryType) {
      case 'INSERT':
      case 'UPDATE':
      case 'DELETE':
        return true;
      case 'SELECT':
      case 'CREATE TABLE':
        return false;
    }
    return false;
  }

  bool get _allowsChaining {
    if (orm.family == ORMDatabaseFamily.postgres) {
      switch (queryType) {
        case 'SELECT':
        case 'INSERT':
        case 'UPDATE':
        case 'DELETE':
          return true;
        case 'CREATE TABLE':
          return false;
      }
    }
    return true;
  }

  // bool get _isDeleteQuery {
  //   return queryType == 'DELETE';
  // }

  ChainedQuery where(List<ORMWhereOperation> operations) {
    if (operations.isEmpty) {
      return this;
    }
    if (orm.family == ORMDatabaseFamily.postgres) {
      _checkIfChainingIsAllowed();
      add('WHERE');
      if (operations.length == 1) {
        add(operations.first.toOperation(tableAliasPrefix));
      } else if (operations.length > 1) {
        for (var i = 0; i < operations.length; i++) {
          final operation = operations[i];
          add(operation.toOperation(tableAliasPrefix));
          if (i != operations.length - 1) {
            add(operation.nextJoiner.toDatabaseOperation());
          }
        }
      }
    }
    return this;
  }

  ChainedQuery offset(
    int offset,
  ) {
    if (orm.family == ORMDatabaseFamily.postgres) {
      _checkIfChainingIsAllowed();
      add('OFFSET $offset');
    }
    return this;
  }

  ChainedQuery limit(
    int limit,
  ) {
    if (orm.family == ORMDatabaseFamily.postgres) {
      _checkIfChainingIsAllowed();
      add('LIMIT $limit');
    }
    return this;
  }

  ChainedQuery orderBy(
    ORMOrderByOperation operation,
  ) {
    if (orm.family == ORMDatabaseFamily.postgres) {
      _checkIfChainingIsAllowed();

      // _addOrderByOperations(operations);
    }
    return this;
  }

  void _checkIfChainingIsAllowed() {
    if (!_allowsChaining) {
      throw Exception('Chaining is not allowed for $queryType queries');
    }
  }

  void printQuery() {
    print('PREPARED QUERY:\n\n${toQueryString()}');
  }

  String toQueryString({
    bool addSemicolon = true,
  }) {
    return '${_parts.join(' ')}${addSemicolon ? ';' : ''}';
  }

  Future<List> toListAsync() async {
    final executeResult = await execute();
    if (executeResult is List) {
      return executeResult.map((e) {
        return type!.fromJson(
          e,
          useValidators: false,
        );
      }).toList();
    }
    return [];
  }

  Future<Object?> execute<T>({
    Duration? timeout,
    bool dryRun = false,
    bool returnResult = false,
  }) async {
    if (returnResult) {
      if (_canAddReturningStatementAtTheEnd) {
        add('RETURNING *');
      }
    }
    final query = toQueryString();

    OrmError? error;
    Object? successResult;
    Object? unknownError;
    List<String> queriesToExecute = [
      query,
    ];

    if (query.contains(ChainedQuery.delimiter)) {
      /// this can be the case for some queries
      queriesToExecute = query
          .split(ChainedQuery.delimiter)
          .where(
            (e) => e.isNotEmpty,
          )
          .map((e) => e.trim())
          .toList();
    }
    // print(queriesToExecute.join('\n'));
    for (var i = 0; i < queriesToExecute.length; i++) {
      final query = queriesToExecute[i];
      final result = await orm.executeSimpleQuery(
        query: query,
        timeout: timeout,
        dryRun: dryRun,
      );
      if (result is List && result.isNotEmpty) {
        if (result.first is Map) {
          // final roles = result.first['roles'] as pgsl.UndecodedBytes;
          // var decodedRoles = utf8.decode(roles.bytes);
          // print(decodedRoles);
          alwaysIncludeParentFields = true;
          successResult = result.map((e) {
            return type!.fromJson(
              e,
              useValidators: false,
            );
          }).toList();
          break;
        }
      } else if (result is OrmError) {
        error = result;
      }
    }
    if (successResult != null) {
      return successResult;
    } else if (error != null) {
      return error;
    } else {
      return unknownError;
    }
  }
}

FieldDescription getFieldDescription({
  required String fieldName,
  required Type fieldDartType,
  required List<InstanceMirror> metadata,
}) {
  List<ORMTableColumnAnnotation> columnAnnotations = [];

  if (metadata.isNotEmpty) {
    /// row annotations are required to apply adjusted data types
    /// instead of the evaluated based on the field type
    columnAnnotations.addAll(
      metadata.where((e) {
        return e.reflectee is ORMTableColumnAnnotation;
      }).map((e) => e.reflectee),
    );
  }

  /// Any "syntactic sugar" for the field can be processed here
  final indexOfDefaultId = columnAnnotations.indexWhere((e) => e is ORMDefaultId);
  if (indexOfDefaultId != -1) {
    columnAnnotations.removeAt(indexOfDefaultId);
    columnAnnotations.insertAll(
      indexOfDefaultId,
      [
        ORMPrimaryKeyColumn(),
        ORMNotNullColumn(),
        ORMUniqueColumn(autoIncrement: true),
      ],
    );
  }
  final databaseType = fieldDartType.toDatabaseType(
    columnAnnotations,
    fieldName,
  );
  // print(databaseType);
  final otherColumnAnnotations = columnAnnotations.where((e) {
    return e is! ORMLimitColumn;
  }).toList();
  otherColumnAnnotations.sort((a, b) => a.order.compareTo(b.order));

  // bool hasUniqueConstraints = otherColumnAnnotations.any((e) => e is ORMUniqueColumn || e is ORMPrimaryKeyColumn);

  final fieldDescription = FieldDescription(
    columnAnnotations: columnAnnotations,
    fieldName: fieldName,
    dartType: fieldDartType,
    // hasUniqueConstraints: hasUniqueConstraints,
    dataTypes: [
      databaseType,
      ...otherColumnAnnotations.mapIndexed(
        (int index, ORMTableColumnAnnotation e) {
          var value = e.getValueForType(
            fieldDartType,
            fieldName,
          );
          if (e is ORMForeignKeyColumn) {
            if (index > 0) {
              value = ', $value';
            }
          }
          return value;
        },
      )
    ]
        .where(
          (element) => element.isNotEmpty,
        )
        .toList(),
  );
  return fieldDescription;
}

/// when a type is decomposed using mirrors, the SDK created a list of
/// [FieldDescription] objects that describe each field
/// of the type to prepare a database query
class FieldDescription {
  FieldDescription({
    required this.dataTypes,
    required this.dartType,
    required this.fieldName,
    required this.columnAnnotations,
  });

  /// this can contain a list of data types
  /// for example [VARCHAR(50), 'SERIAL', 'PRIMARY KEY', 'NOT NULL'] etc.
  /// it will be joined when query is about to be executed
  final List<String> dataTypes;
  final String fieldName;
  final Type dartType;

  bool get hasUniqueConstraint {
    return columnAnnotations.any((e) => e is ORMUniqueColumn || e is ORMPrimaryKeyColumn);
  }

  bool get hasIndexColumn {
    return columnAnnotations.any((e) => e is ORMIndexColumn);
  }

  bool get isIndex {
    return hasIndexColumn || hasUniqueConstraint;
  }

  final List<ORMTableColumnAnnotation> columnAnnotations;

  @override
  String toString() {
    return '${fieldName.wrapInDoubleQuotesIfNeeded()} ${dataTypes.join(' ')}';
  }
}
