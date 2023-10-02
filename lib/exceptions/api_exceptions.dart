import 'dart:io';

/// You can throw these exceptions from anywhere while calling 
/// an endpoint method, even from an annotation and it will be correctly 
/// converted to a response

class NotFoundException extends ApiException {
  NotFoundException({
    required super.message,
    super.traceId,
  }) : super(
          statusCode: HttpStatus.notFound,
        );
}

class InternalServerException extends ApiException {
  InternalServerException({
    required super.message,
    super.traceId,
  }) : super(
          statusCode: HttpStatus.internalServerError,
        );
}

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
