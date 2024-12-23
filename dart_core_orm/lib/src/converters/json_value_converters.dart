import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

/// PostgreSQL dart driver does't understand ARAAY[]
/// so it returns in as UndecodedBytes. In this ORM we
/// store enums as ARRAY[] of strings. So this converter
/// is required to correctly process UndecodedBytes
class ORMEnumConverter extends JsonValueConverter {
  const ORMEnumConverter();

  @override
  Object? convert(
    covariant Object? value,
    SerializationDirection direction,
  ) {
    if (direction == SerializationDirection.fromJson) {
      if (value is UndecodedBytes) {
        var decodedRoles = utf8.decode(value.bytes);
        if (decodedRoles.startsWith('{') && decodedRoles.endsWith('}')) {
          /// usuablly the array is stored as somethind like this "{editor}"
          /// so we try tocnvert it to a noraml dart list presentation
          final asListNotation = decodedRoles
              .substring(
                1,
                decodedRoles.length - 1,
              )
              .split(',');
          return asListNotation;
        }
        return null;
      }
    }
    return value;
  }
}
