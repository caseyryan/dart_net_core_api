import 'dart:io';

/// You can throw these exceptions from anywhere while calling
/// an endpoint method, even from an annotation and it will be correctly
/// converted to a response

class NotFoundException extends ApiException {
  NotFoundException({
    required super.message,
    super.traceId,
    super.code,
  }) : super(
          statusCode: HttpStatus.notFound,
        );
}

class BadRequestException extends ApiException {
  BadRequestException({
    required super.message,
    super.traceId,
    super.code,
  }) : super(statusCode: HttpStatus.badRequest);
}

class ForbiddenException extends ApiException {
  ForbiddenException({
    required super.message,
    super.traceId,
    super.code,
  }) : super(statusCode: HttpStatus.forbidden);
}
class UnAuthorizedException extends ApiException {
  UnAuthorizedException({
    super.message = 'Unauthorized',
    super.traceId,
    super.code,
  }) : super(statusCode: HttpStatus.unauthorized);
}

class UnsupportedMediaException extends ApiException {
  UnsupportedMediaException({
    required super.message,
    super.traceId,
    super.code,
  }) : super(statusCode: HttpStatus.unsupportedMediaType);
}

class ConflictException extends ApiException {
  ConflictException({
    required super.message,
    super.traceId,
    super.code,
  }) : super(statusCode: HttpStatus.conflict);
}

class InternalServerException extends ApiException {
  InternalServerException({
    required super.message,
    super.traceId,
    super.code,
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

  /// [code] might be used in some cases where you
  /// need to distinguish some error from other even if
  /// a status code is the same as in other cases
  String? code;

  ApiException({
    required this.message,
    this.traceId,
    this.statusCode = HttpStatus.badRequest,
    this.code,
  });
}
