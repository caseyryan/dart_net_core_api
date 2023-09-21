import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/controllers/api_controller.dart';

class TestController extends ApiController {


  @HttpPost('/user/[:id]')
  Future<String> getUser(int id) async {
    return 'Вася Пупкин';
  }
}