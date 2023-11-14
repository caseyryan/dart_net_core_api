import 'dart:collection';
import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';

RegExp _uppercase = RegExp(r'[A-Z]');
RegExp _oddUnderscores = RegExp(r'_{2,}');

final _oddEndSlashRegexp = RegExp(r'[\/]+$');
final _oddStartSlashRegexp = RegExp(r'^[\/]+');

extension StringExtensions on String {
  String firstToUpperCase() {
    if (isEmpty) return this;
    final first = this[0].toUpperCase();
    return '$first${substring(1)}';
  }

  /// Specially for MongoDB. Converts a string 
  /// to [ObjectId]. It will work if the string is 
  /// in a correct format
  ObjectId toObjectId() {
    return ObjectId.fromHexString(this);
  }

  /// just removes unnecessary slashes from endpoint
  /// declaration. So you may write /api/v1/ or even
  /// /api/v1//// and it will still use the correct
  /// record /api/v1 without a trailing slash
  String fixEndpointPath() {
    final result =
        replaceAll(_oddEndSlashRegexp, '').replaceAll(_oddStartSlashRegexp, '/');
    if (result.isNotEmpty) {
      if (!result.startsWith('/')) {
        return '/$result';
      }
    }
    return result;
  }

  String camelToSnake() {
    if (isEmpty) return this;
    final presplit = split('');
    final buffer = StringBuffer();
    for (var i = 0; i < presplit.length; i++) {
      final letter = presplit[i];
      if (_uppercase.hasMatch(letter)) {
        if (i > 0) {
          buffer.write('_');
        }
        buffer.write(letter.toLowerCase());
      } else {
        buffer.write(letter);
      }
    }
    return buffer.toString();
  }

  String snakeToCamel() {
    if (isEmpty) return this;
    final str = replaceAll(_oddUnderscores, '_');
    final presplit = str.split('');

    final buffer = StringBuffer();
    for (var i = 0; i < presplit.length; i++) {
      final letter = presplit[i];
      if (letter == '_') {
        if (i == 0) {
          continue;
        }
        if (i < presplit.length - 1) {
          final nextLetter = presplit[i + 1];
          if (i > 1) {
            buffer.write(nextLetter.toUpperCase());
            i++;
          } else {
            buffer.write(nextLetter);
            i++;
          }
        }
      } else {
        buffer.write(letter);
      }
    }
    return buffer.toString();
  }
}

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

  // String _splitByCamelCase(String camelCaseWord) {
  //   var words = camelCaseWord.split(RegExp(r"(?=[A-Z])"));
  //   return words.map((e) => _capitalizeString(e)).join(' ');
  // }

  // String _capitalizeString(String string) {
  //   return "${string[0].toUpperCase()}${string.substring(1)}";
  // }

  String toFormattedJson({
    bool includeNull = false,
  }) {
    var map = {};
    for (var kv in entries) {
      if (kv.value == null) {
        continue;
      }
      map[kv.key] = kv.value;
    }
    return JsonEncoder.withIndent("  ").convert(map);
  }
}
