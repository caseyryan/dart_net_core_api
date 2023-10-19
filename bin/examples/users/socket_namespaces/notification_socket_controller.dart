import 'package:dart_net_core_api/annotations/socket_controller_annotations.dart';
import 'package:dart_net_core_api/base_services/socket_service/socket_controller.dart';


@SocketJwtAuthorization()
@SocketNamespace(path: '/notifications')
class NotificationSocketController extends SocketController {
  NotificationSocketController();
}
