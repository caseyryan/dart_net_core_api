import 'dart:convert';

extension MapExtensions on Map {
  String toFormattedJson() {
    return const JsonEncoder.withIndent('  ').convert(this);
  }
}
