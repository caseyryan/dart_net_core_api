import 'package:dart_net_core_api/exports.dart';

@SnakeToCamel()
class JwtConfig implements IConfig {
  String? hmacKey;
  String? refreshTokenHmacKey;
  String? issuer;
  int? bearerLifeSeconds;
  int? refreshLifeSeconds;
  bool useRefreshToken = false;

  DateTime calculateBearerExpirationDateTime() {
    return utcNow.add(Duration(seconds: bearerLifeSeconds ?? 3600));
  }

  DateTime calculateRefreshExpirationDateTime() {
    return utcNow.add(Duration(seconds: refreshLifeSeconds ?? 3600 * 24));
  }
}
