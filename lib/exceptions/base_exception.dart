/// This exception is throws from the server core
/// and can later be converted to anythong you want
class ApiException implements Exception {
  final String message;
  final String traceId;
  final int statusCode;

  ApiException({
    required this.message,
    required this.traceId,
    this.statusCode = 400,
  });
}
