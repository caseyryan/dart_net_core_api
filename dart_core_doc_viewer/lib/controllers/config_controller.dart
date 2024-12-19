import 'package:lite_state/lite_state.dart';

ConfigController get configController {
  return findController<ConfigController>();
}

class ConfigController extends LiteStateController<ConfigController> {


  String get baseApiUrl {
    return 'http://localhost:8084';
  }
  
  @override
  void reset() {
    
  }
  @override
  void onLocalStorageInitialized() {
    
  }
}