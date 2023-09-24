import 'package:dart_net_core_api/server.dart';

import 'test_controller.dart';

void main(List<String> arguments) {
  Server(
    apiControllers: [
      TestController,
    ],
    singletonServices: [
      Service1(),
    ],
  );
}



class Service1 extends IService {}

class Service2 extends IService {}
