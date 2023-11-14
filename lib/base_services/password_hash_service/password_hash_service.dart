import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:dart_net_core_api/database/configs/password_hash_config.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:uuid/uuid.dart';

import 'pbkdf2.dart';

class PasswordHashService extends Service {
  String generatePublicKeyForRefresh() {
    return hash(Uuid().v4());
  }

  bool isPasswordOk({
    required String existingHash,
    required String rawPassword,
  }) {
    return existingHash == hash(rawPassword);
  }

  String hash(
    String password,
  ) {
    final generator = PBKDF2(
      hashAlgorithm: sha512,
    );
    String? salt = getConfig<PasswordHashConfig>()?.salt;
    int hashRounds = 1000;
    int hashLength = 32;

    assert(
      salt != null,
      'You must provide salt for a hashing algorithm in a config file or an environment variable',
    );
    return generator.generateBase64Key(
      password,
      salt!,
      hashRounds,
      hashLength,
    );
  }

  @override
  FutureOr dispose() {}

  @override
  FutureOr onReady() {}
}
