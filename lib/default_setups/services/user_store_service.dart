import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
import 'package:dart_net_core_api/utils/extensions/extensions.dart';

import '../models/mongo_models/user.dart';
import 'mongo_store_service.dart';

class UserStoreService extends MongoStoreService<User> {
  UserStoreService()
      : super(
          // collectionName: 'users',
          indices: const [
            MongoCollectionIndex(
              name: 'email',
              key: 'email',
              unique: true,
            ),
            MongoCollectionIndex(
              name: 'phone',
              key: 'phone',
              unique: true,
            ),
          ],
        );

  Future<User?> findUserByEmail(String email) async {
    return await findOneAsync(selector: {'email': email});
  }

  Future<User?> findUserByPhone(String phone) async {
    return await findOneAsync(selector: {
      'phone': phone,
    });
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

  Future<User?> findUserById(
    Object id, {
    bool throwErrorIfNotFound = false,
  }) async {
    final user = await findOneAsync(
      selector: {'_id': id.toObjectId()},
    );
    if (throwErrorIfNotFound) {
      if (user == null) {
        throw NotFoundException(
          message: 'User not found',
        );
      }
    }

    return user;
  }

  Future deleteUserById(String id) async {}

  Future insertUser(User user) async {}

  @override
  Future onReady() async {}
}
