import 'package:dart_net_core_api/annotations/socket_controller_annotations.dart';
import 'package:dart_net_core_api/base_services/socket_service/socket_controller.dart';

import '../models/user.dart';

@SocketJwtAuthorization()
@SocketNamespace(path: '/notifications')
class NotificationSocketController extends SocketController {
  NotificationSocketController();

  @RemoteMethod(
    name: 'getProfile',
    responseReceiverName: 'onProfile',
  )
  Future<void> getProfile(
    int id,
    bool withAge, {
    String? firstName,
    required String lastName,
  }) async {
    print('CLIENT CALLED REMOTE METHOD');
    final user = User()
      ..firstName = firstName
      ..lastName = lastName
      ..age = 18;
    // return null;
  }

  @override
  void dispose() {}

  @override
  void onConnected() {
  }
  
  @override
  void onDisconnected() {
    // TODO: implement onDisconnected
  }
}
