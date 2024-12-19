import 'package:dart_core_doc_viewer/api/base_api_dio.dart';
import 'package:dart_core_doc_viewer/api/doc_api_dio.dart';
import 'package:lite_state/lite_state.dart';

class MainPageController extends LiteStateController<MainPageController> {
  
  @override
  void reset() {
    
  }

  Future loadDocumentation() async {
    startLoading();
    final documentation = await api<DocApiDio>().getDocumentation();
    stopLoading();
  } 

  @override
  void onLocalStorageInitialized() {
    
  }
}