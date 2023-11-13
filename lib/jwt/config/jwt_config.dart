import 'package:dart_net_core_api/config.dart';

class JwtConfig implements IConfig {
  late String hmacKey;
  String? refreshTokenHmacKey;
  late String issuer;
  late int bearerLifeSeconds;
  int? refreshLifeSeconds;
  bool useRefreshToken = false;

  DateTime get bearerExpirationDateTime {
    return DateTime.now().toUtc().add(Duration(seconds: bearerLifeSeconds));
  }

  DateTime get refreshExpirationDateTime {
    return DateTime.now().toUtc().add(Duration(seconds: refreshLifeSeconds ?? 0));
  }
}
