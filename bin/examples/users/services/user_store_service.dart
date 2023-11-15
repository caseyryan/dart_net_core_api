import 'package:mongo_dart/mongo_dart.dart';

import '../models/database_models/user.dart';
import 'mongo_store_service.dart';

class UserStoreService extends MongoStoreService<User> {
  UserStoreService()
      : super(
        // collectionName: 'users',
        );

  Future<User?> findUserByEmail(String email) async {
    return await findOneAsync(selector: {'email': email});
  }

  Future<User?> findUserByPhone(String phone) async {
    return await findOneAsync(selector: {'phone': phone});
  }

  Future<User?> findUserByPhoneOrEmail({
    String? phone,
    String? email,
  }) async {
    if (email?.isNotEmpty == true && phone?.isNotEmpty == true) {
      return await findUserByEmail(email!) ?? await findUserByPhone(phone!);
    } else if (email?.isNotEmpty == true) {
      return await findUserByEmail(email!);
    } else if (phone?.isNotEmpty == true) {
      return await findUserByPhone(phone!);
    }
    return null;
  }

  Future<User?> findUserById(String id) async {
    return await findOneAsync(selector: {'_id': ObjectId.fromHexString(id)});
  }

  Future deleteUserById(String id) async {}

  Future insertUser(User user) async {}

  @override
  Future onReady() async {}
}
