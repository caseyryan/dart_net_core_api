import 'dart:convert';
import 'dart:io';

import 'package:dart_net_core_api/exceptions/base_exception.dart';

Future<Object?> tryReadBody(
  HttpRequest request,
  String traceId,
) async {
  final ct = request.headers.contentType;
  try {
    print(ct);
    if (ct == ContentType.text || ct == ContentType.html) {
      return await utf8.decodeStream(request);
    } else if (ct?.value == 'multipart/form-data') {
      final boundary = request.headers.contentType?.parameters['boundary'];
      print(boundary);
      
        // form data object available here.
    }
  } catch (e) {
    throw ApiException(
      message: 'Could not read request body ${e.toString()}',
      traceId: traceId,
    );
  }

  // request.headers.contentType == ContentType.text
  return null;
}
