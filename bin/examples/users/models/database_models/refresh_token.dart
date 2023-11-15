import 'package:mongo_dart/mongo_dart.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

import 'mongo_model.dart';

@JsonIncludeParentFields()
class RefreshToken extends MongoModel {
  String? refreshToken;
  String? publicKey;
  ObjectId? userId;
  DateTime? expiresAt;

  bool get isExpired {
    if (expiresAt == null) {
      return true;
    }
    return DateTime.now().toUtc().isAfter(expiresAt!);
  }
}