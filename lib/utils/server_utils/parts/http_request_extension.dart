part of '../../../server.dart';

extension HttpRequestExtension on HttpHeaders {
  String? get authorization {
    return value('authorization');
  }

  String? get acceptLanguage {
    return value('accept-language');
  }
}
