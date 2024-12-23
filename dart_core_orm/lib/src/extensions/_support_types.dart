part of 'type_extension.dart';

class _SimpleTableScheme {
  final String? newTableName;
  final String? oldTableName;
  final List<_SimpleColumnScheme> columns;

  _SimpleTableScheme._({
    required this.newTableName,
    required this.oldTableName,
    required this.columns,
  });

  String toAlterTableQuery(Type type) {
    // final classReflection = reflectClass(type);
    // final fieldDescription = classReflection.getFieldsDescription(
    //   type,
    // );
    
    return '';
  }

  /// Example:  // [{column_name: id, data_type: integer}, {column_name: updatedAt, data_type: timestamp without time zone}, {column_name: isDeleted, data_type: boolean}, {column_name: birthDate, data_type: date}, {column_name: createdAt, data_type: timestamp without time zone}, {column_name: email, data_type: text}, {column_name: name, data_type: text}]
  factory _SimpleTableScheme.fromPostgresRawList({
    required String? newTableName,
    required String? tableName,
    required List value,
  }) {
    final columns = value.map((e) {
      return _SimpleColumnScheme.fromPostgresMap(e);
    }).toList();

    return _SimpleTableScheme._(
      columns: columns,
      newTableName: newTableName,
      oldTableName: tableName,
    );
  }

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('SimpleTableScheme:');
    if (newTableName != null) {
      buffer.writeln('newTableName: $newTableName');
    }
    if (oldTableName != null) {
      buffer.writeln('tableName: $oldTableName');
    }
    buffer.writeln('columns:');
    for (var i = 0; i < columns.length; i++) {
      final column = columns[i];
      buffer.writeln('  $i: ${column.columnName} - ${column.dataType}');
    }
    return buffer.toString();
  }
}

class _SimpleColumnScheme {
  final String columnName;
  final Object? dataType;

  _SimpleColumnScheme._({
    required this.columnName,
    required this.dataType,
  });

  static Object? _tryInferDartType(String dataTypeName) {
    final lowerType = dataTypeName.toLowerCase();
    if (lowerType.contains('int') || lowerType.contains('serial')) {
      return int;
    }
    if (lowerType.contains('text') || lowerType.contains('varchar')) {
      return String;
    }
    if (lowerType.contains('timestamp') ||
        lowerType.contains('date') ||
        lowerType.contains('time')) {
      return DateTime;
    }
    if (lowerType.contains('boolean')) {
      return bool;
    }
    return null;
  }

  factory _SimpleColumnScheme.fromPostgresMap(Map value) {
    final dartType = _tryInferDartType(value['data_type']);
    if (dartType == null) {
      throw Exception('Cannot infer data type from: ${value['data_type']}');
    }
    return _SimpleColumnScheme._(
      columnName: value['column_name'],
      dataType: dartType,
    );
  }
}
