import 'package:dart_core_orm/dart_core_orm.dart';

/// Creates a trigger for a postgresql database
/// that will update the updated_at column
/// when a row is inserted or updated
/// for not supported databases it will return null
String? createUpdatedAtTriggerCode({
  required String tableName,
  String? columnName = 'updated_at',
}) {
  columnName = columnName?.wrapInDoubleQuotesIfNeeded();

  if (orm.family == ORMDatabaseFamily.postgres) {
    final triggerCode = '''
\nCREATE OR REPLACE FUNCTION update_date_column()
RETURNS TRIGGER AS
\$\$
BEGIN
    NEW.$columnName = now();
    RETURN NEW;
END;
\$\$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_date_column
BEFORE INSERT OR UPDATE ON $tableName
FOR EACH ROW EXECUTE FUNCTION update_date_column()
''';
    return triggerCode;
  }
  return null;
}
