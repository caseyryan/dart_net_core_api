import 'package:dart_net_core_api/config.dart';

class JwtConfig implements IConfig {
  late String hmacKey;
  late String refreshTokenHmac;
  late String issuer;
  late int bearerLifeSeconds;
  late int refreshLifeSeconds;

  DateTime get bearerExpirationDateTime {
    return DateTime.now().toUtc().add(Duration(seconds: bearerLifeSeconds));
  }

  DateTime get refreshExpirationDateTime {
    return DateTime.now().toUtc().add(Duration(seconds: refreshLifeSeconds));
  }
}