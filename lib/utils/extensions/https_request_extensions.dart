import 'dart:io';

extension HttpRequestExtension on HttpRequest {

  ContentType get acceptContentType {
    final accept = headers.value(HttpHeaders.acceptHeader);
    if (accept == null) {
      return ContentType('*', '*');
    }
    return ContentType.parse(accept);
  }


  void ensureCharsetPresent() {
    /// Uses JSON by default
    if (headers.contentType == null) {
      response.headers.contentType = ContentType.json;
    } else if (headers.contentType?.value == 'application/json') {
      if (headers.contentType?.charset == null) {
        /// so we could use utf-8 by default if other is not provided
        response.headers.contentType = ContentType.json;
      }
    }
  }
}


extension ContentTypeExtension on ContentType {
  bool get isJson {
    return primaryType == ContentType.json.primaryType && subType == ContentType.json.subType;
  }

  bool get canAcceptFile {
    return isAnyContent || primaryType == ContentType.binary.primaryType || primaryType == 'image' || primaryType == 'video';
  }

  bool get isAnyContent {
    return primaryType == '*' && subType == '*';
  }
}