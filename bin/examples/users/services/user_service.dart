import 'package:mongo_dart/mongo_dart.dart';

import '../models/user.dart';
import 'mongo_service.dart';

class UserService extends MongoService<User> {
  UserService()
      : super(
        // collectionName: 'users',
        );

  Future<User?> findUserByEmail(String email) async {
    return await findOne({'email': email});
  }

  Future<User?> findUserByPhone(String phone) async {
    return await findOne({'phone': phone});
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
    return await findOne({'_id': ObjectId.fromHexString(id)});
  }

  Future deleteUserById(String id) async {}

  Future insertUser(User user) async {}

  @override
  Future onReady() async {}
}
