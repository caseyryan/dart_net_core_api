import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/server.dart';

import 'main.dart';

@BaseApiPath('/api/v1')
class TestController extends ApiController {
  Service1 service;
  double? numericValue;

  TestController(
    this.service,
  ) {
    print('Instantiated a $this with service: $service');
  }

  @HttpGet('/user/{:id}')
  Future<String> getUser({
    required int id,
    required String name,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return 'User id: $id: name: $name, ${httpContext.path}';
  }
}
