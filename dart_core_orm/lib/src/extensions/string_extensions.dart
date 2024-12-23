import 'package:dart_core_orm/src/orm.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

extension StringExtensions on String {
  String sanitize() {
    ORMDatabaseFamily? family = orm.family;
    if (family == ORMDatabaseFamily.postgres) {
      final result = replaceAll(RegExp('[\']{1}'), "''");
      if (result.contains('Heart')) {
        print(result);
      }
      return "'$result'";
    }
    return this;
  }

  String toAlias() {
    final a = CamelToSnake().convert(this).replaceAll('_', '');
    if (a.length >= 3) {
      return a.substring(0, 3);
    }
    return a.isEmpty ? this[0].toLowerCase() : a;
  }

  // String _removeVowels() {
  //   return replaceAll(RegExp('[aeiou]'), '');
  // }

  /// in some databases like PostgreSQL
  /// the names of tables and columns are lowercase by default.
  /// This method will add double quotes around the string
  /// if the database is PostgreSQL and the names are not already
  /// wrapped in double quotes
  /// This will make them case sensitive
  String wrapInDoubleQuotesIfNeeded() {
    if (orm.useCaseSensitiveNames) {
      if (orm.family == ORMDatabaseFamily.postgres) {
        if (!startsWith('"') && !endsWith('"')) {
          return '"$this"';
        }
      }
    }
    return this;
  }

  /// sometimes it's necessary
  String stripWrappingDoubleQuotes() {
    var result = this;
    if (orm.family == ORMDatabaseFamily.postgres) {
      if (startsWith('"') && endsWith('"') && length > 2) {
        result = substring(1, length - 1);
      }
    }
    return result;
  }
}
