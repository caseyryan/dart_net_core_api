import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/jwt/annotations/jwt_auth.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/utils/server_utils/form_entry.dart';

import 'main.dart';

@JwtAuth(roles: ['admin'])
@BaseApiPath('/api/v1')
class TestController extends ApiController {
  Service1 service;
  double? numericValue;

  TestController(
    this.service,
  ) {
    print('Instantiated a $this with service: $service');
  }

  // @JwtAuth(roles: ['user'])
  @HttpGet('/user/{:id}')
  Future<String> getUser({
    required int id,
    required String name,
    // @FromBody() Map? user,
    @FromBody() List<FormEntry>? form,
  }) async {
    
    return 'User id: $id: name: $name, ${httpContext.path}, user: $form';
  }
}
