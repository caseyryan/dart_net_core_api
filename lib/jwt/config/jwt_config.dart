import 'package:dart_net_core_api/config.dart';

class JwtConfig implements IConfig {
  late String hmacKey;
  String? refreshTokenHmacKey;
  late String issuer;
  late int bearerLifeSeconds;
  int? refreshLifeSeconds;
  bool useRefreshToken = false;

  DateTime calculateBearerExpirationDateTime() {
    return DateTime.now().toUtc().add(Duration(seconds: bearerLifeSeconds));
  }

  DateTime calculateRefreshExpirationDateTime() {
    return DateTime.now().toUtc().add(Duration(seconds: refreshLifeSeconds ?? 0));
  }
}
