import 'package:collection/collection.dart';
import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
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

  Future _imitateSomeLoading() async {
    await Future.delayed(const Duration(milliseconds: 50));
  }

  Future<User?> getUserById(String id) async {
    await _imitateSomeLoading();
    return _usersDataBase.firstWhereOrNull((user) => user.id == id);
  }

  Future deleteUserById(String id) async {
    await _imitateSomeLoading();
    if (!_usersDataBase.any((user) => user.id == id)) {
      throw NotFoundException(message: 'User not found `$id`');
    }
    _usersDataBase.removeWhere((user) => user.id == id);
  }

  Future insertUser(User user) async {
    await _imitateSomeLoading();
    if (_usersDataBase.contains(user)) {
      throw 'User ${user.firstName} ${user.lastName} already exists';
    }
    _usersDataBase.add(user);
  }
}
