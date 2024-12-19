import 'package:dart_core_doc_viewer/api/base_api_dio.dart';
import 'package:dart_core_doc_viewer/api/doc_api_dio.dart';
import 'package:dart_core_doc_viewer/api/response_models/documentation_response/api_group_model.dart';
import 'package:dart_core_doc_viewer/api/response_models/documentation_response/controller_api_model.dart';
import 'package:dart_core_doc_viewer/api/response_models/documentation_response/documentation_response.dart';
import 'package:dart_core_doc_viewer/main_page/widgets/group_list.dart';
import 'package:lite_state/lite_state.dart';

class MainPageController extends LiteStateController<MainPageController> {
  DocumentationResponse? _documentationResponse;
  DocumentationResponse? get documentationResponse => _documentationResponse;

  ControllerApiModel? _selectedController;
  ControllerApiModel? get selectedController {
    _selectedController ??= controllers.firstOrNull;
    return _selectedController;
  }

  final List<GroupData> _controllersByGroups = [];
  List<GroupData> get controllersByGroups => _controllersByGroups;

  List<ControllerApiModel> get controllers {
    return documentationResponse?.data?.controllers ?? [];
  }

  bool get hasDocumentationResponse {
    return _documentationResponse != null;
  }

  Future onControllerSelected(ControllerApiModel value) async {

  }

  void onGroupExpanded(GroupData value) {
    // final curValue = value.isExpanded;
    // for (var group in controllersByGroups) {
    //   group.isExpanded = false;
    // }
    value.isExpanded = !value.isExpanded;
    rebuild();
  }

  @override
  void reset() {}

  Future loadDocumentation() async {
    startLoading();
    _controllersByGroups.clear();
    final temp = <ApiGroupModel, List<ControllerApiModel>>{};
    _documentationResponse = await api<DocApiDio>().getDocumentation();
    if (_documentationResponse != null) {
      final c = controllers;
      for (var controller in c) {
        final group = controller.group!;
        if (temp[group] == null) {
          temp[group] = [];
        }
        temp[group]!.add(controller);
      }
    }
    for (var kv in temp.entries) {
      final controllerList = kv.value;
      _controllersByGroups.add(
        GroupData(
          group: kv.key,
          controllers: controllerList,
        ),
      );
    }
    stopLoading();
  }

  @override
  void onLocalStorageInitialized() {}
}
