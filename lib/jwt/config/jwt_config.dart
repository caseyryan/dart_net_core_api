import 'package:dart_net_core_api/config.dart';
import 'package:dart_net_core_api/utils/time_utils.dart';

class JwtConfig implements IConfig {
  late String hmacKey;
  String? refreshTokenHmacKey;
  late String issuer;
  late int bearerLifeSeconds;
  int? refreshLifeSeconds;
  bool useRefreshToken = false;

  DateTime calculateBearerExpirationDateTime() {
    return utcNow.add(Duration(seconds: bearerLifeSeconds));
  }

  DateTime calculateRefreshExpirationDateTime() {
    return utcNow.add(Duration(seconds: refreshLifeSeconds ?? 0));
  }
}
