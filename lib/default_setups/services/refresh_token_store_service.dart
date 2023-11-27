import 'package:dart_net_core_api/utils/extensions/extensions.dart';

import '../models/mongo_models/refresh_token.dart';
import 'mongo_store_service.dart';

class RefreshTokenStoreService extends MongoStoreService<RefreshToken> {

  Future<RefreshToken?> findByUserId(
    dynamic userId,
  ) async {
    if (userId is String) {
      userId = userId.toObjectId();
    }
    return await findOneAsync(selector: {'userId': userId});
  }
}
