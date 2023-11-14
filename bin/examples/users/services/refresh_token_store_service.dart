import 'package:mongo_dart/mongo_dart.dart';

import '../models/refresh_token.dart';
import 'mongo_store_service.dart';

class RefreshTokenStoreService extends MongoStoreService<RefreshToken> {

  Future<RefreshToken?> findByUserId(
    ObjectId userId,
  ) async {
    return await findOne({'userId': userId});
  }
}
