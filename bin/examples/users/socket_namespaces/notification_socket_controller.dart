import 'package:dart_net_core_api/annotations/socket_controller_annotations.dart';
import 'package:dart_net_core_api/base_services/socket_service/socket_controller.dart';

import '../models/database_models/user.dart';

@SocketJwtAuthorization()
@SocketNamespace(path: '/notifications')
class NotificationSocketController extends SocketController {
  NotificationSocketController();

  @RemoteMethod(
    name: 'getProfile',
    responseReceiverName: 'onProfile',
  )
  Future<User?> getProfile(
    int id,
    bool withAge, {
    String? firstName,
    required String lastName,
  }) async {
    print('CLIENT CALLED REMOTE METHOD $client');
    final user = User()
      ..firstName = firstName
      ..lastName = lastName;
    return user;
  }

  @override
  void dispose() {
    print('Dispose Called');
  }

  @override
  void onConnected() {
    print('On Connected');
  }
  
  @override
  void onDisconnected() {
    print('On Disconnected');
  }
}
