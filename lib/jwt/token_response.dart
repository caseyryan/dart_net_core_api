class TokenResponse {
  String? bearerToken;
  String? refreshToken;
  DateTime? bearerExpirationDateTimeUtc;
  DateTime? refreshExpirationDateTimeUtc;
  
  TokenResponse({
    this.bearerToken,
    this.refreshToken,
    this.bearerExpirationDateTimeUtc,
    this.refreshExpirationDateTimeUtc,
  });
}
