import 'package:dart_net_core_api/utils/extensions/extensions.dart';

import '../models/mongo_models/refresh_token.dart';
import 'mongo_store_service.dart';

class RefreshTokenStoreService extends MongoStoreService<RefreshToken> {
  /// [httpContextToValidate] if passed, it will automatically check
  /// the validity of the token
  Future<RefreshToken?> findByUserId({
    required Object userId,
  }) async {
    return await findOneAsync(selector: {
      'userId': userId.toObjectId(),
    });
  }
}
