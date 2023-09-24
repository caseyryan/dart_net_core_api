// ignore_for_file: empty_catches


import 'default_date_parser.dart';

Object? tryConvertArgumentType({
  required String? actual,
  required Type expectedType,
  required DateParser dateParser, 
}) {
  if (actual == null) {
    return null;
  }
  try {
    switch (expectedType) {
      case int:
        return int.tryParse(actual);
      case double:
        return double.tryParse(actual);
      case String:
        return actual;
      case DateTime:
        return parseDateTime(actual);
      case bool:
        return bool.fromEnvironment(
          actual,
          defaultValue: false,
        );
    }
  } catch (e) {}
  return null;
}


/// TODO: Implement different format processing
DateTime? parseDateTime(String value) {
  return DateTime.tryParse(value);
}