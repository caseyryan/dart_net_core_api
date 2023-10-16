import 'package:dart_net_core_api/annotations/socket_controller_annotations.dart';
import 'package:dart_net_core_api/base_services/socket_service/socket_controller.dart';


@SocketJwtAuthorization()
class NotificationSocketController extends SocketController {
  NotificationSocketController({
    required super.namespace,
  });

  Future onClientMessage() async {

  }

}
