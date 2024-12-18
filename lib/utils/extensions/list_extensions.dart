import 'dart:convert';

import 'package:reflect_buddy/reflect_buddy.dart';

extension ListExtensions on List {
  String toFormattedJson({
    bool includeNull = false,
  }) {
    final list = (this as Object).toJson(
      includeNullValues: includeNull,
    );
    return JsonEncoder.withIndent("  ").convert(list);
  }
}