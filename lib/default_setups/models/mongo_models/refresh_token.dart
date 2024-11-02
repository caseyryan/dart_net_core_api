import 'package:dart_net_core_api/utils/time_utils.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

import 'base_mongo_model.dart';

@JsonIncludeParentFields()
class RefreshToken extends BaseModel {
  String? refreshToken;
  String? publicKey;
  ObjectId? userId;
  DateTime? expiresAt;

  bool get isExpired {
    if (expiresAt == null) {
      return true;
    }
    return utcNow.isAfter(expiresAt!);
  }
}