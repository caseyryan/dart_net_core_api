// ignore_for_file: unnecessary_import

import 'package:dart_core_doc_viewer/api/response_models/documentation_response/api_group_model.dart';
import 'package:dart_core_doc_viewer/api/response_models/documentation_response/controller_api_model.dart';
import 'package:dart_core_doc_viewer/constants.dart';
import 'package:dart_core_doc_viewer/controllers/main_page_controller.dart';
import 'package:dart_core_doc_viewer/ui/horizontal_line.dart';
import 'package:dart_core_doc_viewer/ui/themes/theme_switch.dart';
import 'package:flutter/material.dart';
import 'package:lite_forms/base_form_fields/lite_form.dart';
import 'package:lite_forms/lite_forms.dart';

import 'tiles/api_group_tile.dart';

class GroupData {
  final ApiGroupModel group;
  final List<ControllerApiModel> controllers;

  GroupData({
    required this.group,
    required this.controllers,
  });

  bool isExpanded = false;
}

class GroupList extends StatelessWidget {
  const GroupList({
    super.key,
  });

  // final List<GroupData> controllersByGroups;
  // final ValueChanged<GroupData> onExpandToggle;
  // final ValueChanged<ControllerApiModel> onControllerSelected;
  // final ControllerApiModel? selectedController;

  @override
  Widget build(BuildContext context) {
    return LiteState<MainPageController>(
      builder: (BuildContext c, MainPageController controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('API Groups'),
            actions: const [
              Padding(
                padding: EdgeInsets.only(
                  right: kPadding,
                ),
                child: ThemeSwitch(),
              ),
            ],
          ),
          body: SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: LiteForm(
              name: 'apiGroupList',
              builder: (context, scrollController) {
                return Column(
                  children: [
                    const HorizontalLine(),
                    LiteSearchField(
                      paddingLeft: kPadding,
                      paddingRight: kPadding,
                      paddingTop: kPadding,
                      paddingBottom: kPadding,
                      onSearch: controller.onGroupSearch,
                      hintText: 'Filter by all...',
                    ),
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          ...controller.controllersByGroups.map(
                            (e) {
                              return ApiGroupTile(
                                key: ValueKey(e),
                                groupData: e,
                                selectedController: controller.selectedController,
                                onControllerSelected: controller.onControllerSelected,
                                onExpandToggle: controller.onGroupExpanded,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
