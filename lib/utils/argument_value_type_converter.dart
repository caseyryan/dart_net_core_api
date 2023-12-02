// ignore_for_file: empty_catches

import 'package:reflect_buddy/reflect_buddy.dart';

import 'default_date_parser.dart';

Object? tryConvertQueryArgumentType({
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
        return parseDateTime(actual, dateParser);
      case bool:
        return bool.fromEnvironment(
          actual,
          defaultValue: false,
        );
    }
    /// This might come useful if it's an enum, for example
    return expectedType.fromJson(actual);
  } catch (e) {}

  return null;
}

DateTime? parseDateTime(
  String value,
  DateParser dateParser,
) {
  return dateParser.call(value) ?? DateTime.tryParse(value);
}
