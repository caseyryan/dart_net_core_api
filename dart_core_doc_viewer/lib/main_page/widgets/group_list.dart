import 'package:dart_core_doc_viewer/api/response_models/documentation_response/api_group_model.dart';
import 'package:dart_core_doc_viewer/api/response_models/documentation_response/controller_api_model.dart';
import 'package:dart_core_doc_viewer/constants.dart';
import 'package:dart_core_doc_viewer/ui/horizontal_line.dart';
import 'package:dart_core_doc_viewer/ui/themes/theme_switch.dart';
import 'package:flutter/material.dart';

import 'api_group_tile.dart';

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
    required this.controllersByGroups,
    required this.onControllerSelected,
    required this.onExpandToggle,
  });

  final List<GroupData> controllersByGroups;
  final ValueChanged<GroupData> onExpandToggle;
  final ValueChanged<ControllerApiModel> onControllerSelected;

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          children: [
            const HorizontalLine(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  ...controllersByGroups.map(
                    (e) {
                      return ApiGroupTile(
                        key: ValueKey(e),
                        groupData: e,
                        onControllerSelected: onControllerSelected,
                        onExpandToggle: onExpandToggle,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
