import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:dart_net_core_api/database/configs/password_hash_config.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:uuid/uuid.dart';

import 'pbkdf2.dart';

class PasswordHashService extends Service {
  String generatePublicKeyForRefresh() {
    return hash(
      password: Uuid().v4(),
    );
  }

  String hash({
    required String password,
    String? salt,
    int hashRounds = 1000,
    int hashLength = 32,
    Hash? hashFunction,
  }) {
    final generator = PBKDF2(
      hashAlgorithm: hashFunction ?? sha512,
    );
    salt ??= getConfig<PasswordHashConfig>()?.salt;
    assert(salt != null, 'You must provide salt for a hashing algorithm');
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
