import 'dart:io';

/// This exception is throws from the server core
/// and can later be converted to anything you want
class ApiException implements Exception {
  final String message;
  final int statusCode;
  String? traceId;

  ApiException({
    required this.message,
    this.traceId,
    this.statusCode = HttpStatus.badRequest,
  });
}
