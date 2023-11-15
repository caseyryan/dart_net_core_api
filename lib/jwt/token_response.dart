import 'package:reflect_buddy/reflect_buddy.dart';

class TokenResponse {
  String? bearerToken;
  String? refreshToken;
  DateTime? bearerExpiresAt;
  DateTime? refreshExpiresAt;

  @JsonIgnore()
  String? publicKey;

  @JsonIgnore()
  dynamic refreshTokenId;

  bool get isRefreshTokenExpired {
    if (refreshToken == null) {
      return false;
    }
    if (refreshExpiresAt == null) {
      return true;
    }
    return DateTime.now().toUtc().isAfter(refreshExpiresAt!);
  }

  TokenResponse({
    this.bearerToken,
    this.refreshToken,
    this.bearerExpiresAt,
    this.refreshExpiresAt,
    this.publicKey,
  });

  TokenResponse copyWith({
    String? bearerToken,
    String? refreshToken,
    DateTime? bearerExpiresAt,
    DateTime? refreshExpiresAt,
    String? publicKey,
  }) {
    return TokenResponse(
      bearerToken: bearerToken ?? this.bearerToken,
      refreshToken: refreshToken ?? this.refreshToken,
      bearerExpiresAt: bearerExpiresAt ?? this.bearerExpiresAt,
      refreshExpiresAt: refreshExpiresAt ?? this.refreshExpiresAt,
      publicKey: publicKey ?? this.publicKey,
    );
  }
}
