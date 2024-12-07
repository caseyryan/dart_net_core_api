import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/server.dart';

class HealthController extends ApiController {
  
  @HttpGet(
    '/health',
    contentType: 'application/json',
  )
  Future<Map> getHealth() async {
    var env = 'dev';
    if (httpContext.isProd) {
      env = 'prod';
    }
    return {
      'status': 'ok',
      'env': env,
    };
  }
}
