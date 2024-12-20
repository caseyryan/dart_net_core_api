import 'package:dart_core_doc_viewer/api/base_api_dio.dart';
import 'package:dart_core_doc_viewer/api/doc_api_dio.dart';
import 'package:dart_core_doc_viewer/api/response_models/documentation_response/api_endpoint_model.dart';
import 'package:dart_core_doc_viewer/api/response_models/documentation_response/api_group_model.dart';
import 'package:dart_core_doc_viewer/api/response_models/documentation_response/controller_api_model.dart';
import 'package:dart_core_doc_viewer/api/response_models/documentation_response/documentation_response.dart';
import 'package:dart_core_doc_viewer/main_page/widgets/group_list.dart';
import 'package:flutter/material.dart';
import 'package:lite_state/lite_state.dart';

MainPageController get mainPageController {
  return findController<MainPageController>();
}

class MainPageController extends LiteStateController<MainPageController> {


  DocumentationResponse? _documentationResponse;
  DocumentationResponse? get documentationResponse => _documentationResponse;

  ControllerApiModel? _selectedController;
  ControllerApiModel? get selectedController {
    _selectedController ??= controllers.firstOrNull;
    return _selectedController;
  }

  String _endpointSearchValue = '';
  String get endpointSearchValue => _endpointSearchValue;

  String _groupSearchValue = '';
  String get groupSearchValue => _groupSearchValue;

  void onEndpointSearch(String value) {
    debugPrint('ENDPOINT SEARCH VALUE: $value');
    _endpointSearchValue = value;
    rebuild();
  }

  void onGroupSearch(String value) {
    debugPrint('GROUP SEARCH VALUE: $value');
    _groupSearchValue = value;
    rebuild();
  }

  final List<GroupData> _controllersByGroups = [];
  List<GroupData> get controllersByGroups => _controllersByGroups;

  List<ControllerApiModel> get controllers {
    return documentationResponse?.data?.controllers ?? [];
  }

  bool get hasDocumentationResponse {
    return _documentationResponse != null;
  }

  List<ApiEndpointModel> get endpoints {
    final selectedEndpoints = _selectedController?.endpoints ?? [];
    if (_endpointSearchValue.isNotEmpty) {
      return selectedEndpoints.where((e) => e.isMatchingSearch(_endpointSearchValue)).toList();
    }
    return selectedEndpoints;
  }

  void onControllerSelected(ControllerApiModel value)  {
    if (_selectedController == value) {
      return;
    }
    // _searchValue = '';
    _selectedController = value;
    rebuild();
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

  Future loadDocumentation([bool force = false,]) async {
    if (force) {
      _controllersByGroups.clear();
      stopAllLoadings();
    }
    if (isLoading || _controllersByGroups.isNotEmpty) {
      return;
    }
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
