import 'package:collection/collection.dart';
import 'package:dart_net_core_api/server.dart';

import '../models/user.dart';

class UserService extends IService {
  static final List<User> _usersDataBase = [
    User()
      ..age = 23
      ..firstName = 'John'
      ..lastName = 'Doe'
      ..id = 'user-1',
    User()
      ..age = 19
      ..firstName = 'Maria'
      ..lastName = 'Dickens'
      ..id = 'user-2',
    User()
      ..age = 45
      ..firstName = 'Ivan'
      ..lastName = 'Drakov'
      ..id = 'user-3',
  ];

  User? tryFindUserById(String id) {
    return _usersDataBase.firstWhereOrNull((user) => user.id == id);
  }

  void insertUser(User user) {
    if (_usersDataBase.contains(user)) {
      throw 'User ${user.firstName} ${user.lastName} already exists';
    }
    _usersDataBase.add(user);
  }
}
