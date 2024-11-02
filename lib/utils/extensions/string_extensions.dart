// ignore_for_file: empty_catches

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:mongo_dart/mongo_dart.dart';


final RegExp _idRegExp = RegExp(r'^[a-z0-9]{24}$');
final RegExp _numberRegexp = RegExp(r'[0-9,.]+');

final _oddEndSlashRegexp = RegExp(r'[\/]+$');
final _oddStartSlashRegexp = RegExp(r'^[\/]+');

extension StringExtensions on String {
  String firstToUpperCase() {
    if (isEmpty) return this;
    final first = this[0].toUpperCase();
    return '$first${substring(1)}';
  }

  bool get isNumber {
    if (isNotEmpty != true) {
      return false;
    }
    return _numberRegexp.hasMatch(this) == true;
  }


  String toMd5() {
    return md5.convert(utf8.encode(this)).toString();
  }

  ContentType? toContentType() {
    if (!contains('/')) {
      return null;
    }
    try {
      return ContentType.parse(this);
    }
    catch (e){}
    return null;
  }

  bool isMatchingObjectId() {
    return _idRegExp.hasMatch(this);
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