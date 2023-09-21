/// This exception is throws from the server core
/// and can later be converted to anythong you want
class DartApiException implements Exception {
  final String message;
  final String traceId;

  DartApiException(
    this.message,
    this.traceId,
  );
}
