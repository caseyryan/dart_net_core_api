import 'dart:collection';
import 'dart:convert';

import 'package:reflect_buddy/reflect_buddy.dart';

extension MapExtensions on Map<dynamic, dynamic> {
  String toBase64() {
    return base64.encode(
      utf8.encode(jsonEncode(this)),
    );
  }

  String toQueryParams() {
    var hashSet = HashSet<String>();
    forEach((key, value) {
      hashSet.add("$key=$value");
    });
    return hashSet.join('&');
  }

  void copyAllFrom(Map other) {
    for (var kv in other.entries) {
      this[kv.key] = kv.value;
    }
  }

  String toFormattedJson({
    bool includeNull = false,
  }) {
    var map = (this as Object).toJson(includeNullValues: includeNull);
    return JsonEncoder.withIndent("  ").convert(map);
  }
}

