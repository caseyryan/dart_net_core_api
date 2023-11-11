import '../models/user.dart';
import 'mongo_service.dart';

class UserService extends MongoService<User> {
  UserService()
      : super(
          // collectionName: 'users',
        );

  Future<User?> getUserByEmail() async {
    
    return null;
  }

  Future<User?> getUserById(String id) async {
    return null;
  }

  Future deleteUserById(String id) async {}

  Future insertUser(User user) async {}

  @override
  Future onReady() async {
    
  }

  
}
