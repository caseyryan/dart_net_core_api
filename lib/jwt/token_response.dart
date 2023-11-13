class TokenResponse {
  String? bearerToken;
  String? refreshToken;
  DateTime? bearerExpiresAt;
  DateTime? refreshExpiresAt;
  
  TokenResponse({
    this.bearerToken,
    this.refreshToken,
    this.bearerExpiresAt,
    this.refreshExpiresAt,
  });
}
