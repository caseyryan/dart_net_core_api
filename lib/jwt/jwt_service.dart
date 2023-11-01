import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dart_net_core_api/jwt/config/jwt_config.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

/// It's a basic JwtService. You can extend this class
/// and write your own validation and generation logic if you need
class JwtService extends Service {
  int get _issuedAt {
    return DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  }

  int getBearerExpiration(int bearerLifeSeconds) {
    return DateTime.now().toUtc()
            .add(
              Duration(seconds: bearerLifeSeconds),
            )
            .millisecondsSinceEpoch ~/
        1000;
  }

  /// Generates a Bearer token
  /// [payload] any object that will be serialized and saved in this
  /// token. Typically it contains some data you want to add to a token
  /// like user id or some unique key. It's better
  /// be a flat structure with some simple data
  String generateBearer({
    required JwtConfig config,
    Object? payload,
    Audience? audience,
    JWTAlgorithm algorithm = JWTAlgorithm.HS512,
    int? iat,
    int? exp,
  }) {
    final body = <String, dynamic>{
      'iat': iat ?? _issuedAt,
      'exp': exp ??
          getBearerExpiration(
            config.bearerLifeSeconds,
          ),
    };
    if (audience?.isNotEmpty == true) {
      body['aud'] = audience!.toList();
    }
    if (payload != null) {
      final data = payload.toJson();
      body['payload'] = data;
    }
    final jwt = JWT(
      body,
      issuer: config.issuer,
    );

    return jwt.sign(
      SecretKey(config.hmacKey),
      algorithm: algorithm,
    );
  }

  Map<String, dynamic>? decodeBearer({
    required String token,
    required JwtConfig config,
    Type? payloadType,
    Audience? audience,
  }) {
    final Map<String, dynamic>? data = JWT
        .tryVerify(
          token,
          SecretKey(
            config.hmacKey,
          ),
          audience: audience,
        )
        ?.payload;
    if (data == null) {
      throw 'Invalid bearer';
    }
    if (payloadType != null) {
      if (data.containsKey('payload')) {
        data['payload'] = payloadType.fromJson(data['payload']);
      }
    }

    return data;
  }

  @override
  void onReady() {}

  // Map? decodeRefreshToken(String refreshToken) {
  //   final data = JWT
  //       .tryVerify(
  //         refreshToken,
  //         SecretKey(
  //           config.jwt.refreshTokenHmac,
  //         ),
  //       )
  //       ?.payload as Map?;
  //   if (data == null) {
  //     throw 'Невалидный refreshToken';
  //   }
  //   return data;
  // }

  // Map? decodeBearerToken(String bearerToken) {
  //   final data = JWT
  //       .tryVerify(
  //         bearerToken,
  //         SecretKey(
  //           config.jwt.hmacKey,
  //         ),
  //       )
  //       ?.payload as Map?;
  //   if (data == null) {
  //     throw 'Невалидный Bearer';
  //   }
  //   return data;
  // }

  // bool isRefreshTokenValid({
  //   required String? refreshToken,
  // }) {
  //   if (refreshToken == null) {
  //     return false;
  //   }
  //   try {
  //     JWT.verify(
  //       refreshToken,
  //       SecretKey(
  //         config.jwt.refreshTokenHmac,
  //       ),
  //     );
  //     return true;
  //   } on JWTExpiredError {
  //     print('jwt expired');
  //   } on JWTError catch (ex) {
  //     print(ex.message);
  //   } catch (e) {
  //     return false;
  //   }
  //   return false;
  // }

  // bool isBearerTokenValid({
  //   required String? bearerToken,
  //   required String? refreshToken,
  // }) {
  //   if (refreshToken == null || bearerToken == null) {
  //     return false;
  //   }
  //   try {
  //     if (!isRefreshTokenValid(
  //       refreshToken: refreshToken,
  //     )) {
  //       return false;
  //     }
  //     final refreshData = decodeRefreshToken(refreshToken);
  //     final jwt = JWT.verify(
  //       bearerToken,
  //       SecretKey(
  //         config.jwt.hmacKey,
  //       ),
  //     );
  //     final payload = jwt.payload as Map;
  //     final bearerKey = payload['key'];
  //     final refreshKey = refreshData!['key'];
  //     if (refreshKey != bearerKey) {
  //       return false;
  //     }
  //     return true;
  //   } on JWTExpiredError {
  //     print('jwt expired');
  //   } on JWTError catch (ex) {
  //     print(ex.message);
  //   } catch (e) {
  //     return false;
  //   }
  //   return false;
  // }
}
