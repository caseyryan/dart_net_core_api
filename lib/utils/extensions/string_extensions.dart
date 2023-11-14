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
}