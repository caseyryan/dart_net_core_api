import 'package:dart_core_doc_viewer/api/response_models/documentation_response/controller_api_model.dart';
import 'package:dart_core_doc_viewer/constants.dart';
import 'package:dart_core_doc_viewer/main_page/widgets/group_list.dart';
import 'package:dart_core_doc_viewer/ui/horizontal_line.dart';
import 'package:flutter/material.dart';

class ApiGroupTile extends StatelessWidget {
  const ApiGroupTile({
    super.key,
    required this.groupData,
    required this.onExpandToggle,
    required this.onControllerSelected,
  });

  final ValueChanged<GroupData> onExpandToggle;
  final ValueChanged<ControllerApiModel> onControllerSelected;

  final GroupData groupData;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          ListTile(
            title: Text(groupData.group.title),
            onTap: () {
              onExpandToggle(groupData);
            },
          ),
          if (groupData.isExpanded)
            ...groupData.controllers.map(
              (e) {
                return ListTile(
                  key: ValueKey(e),
                  title: Padding(
                    padding: const EdgeInsets.only(
                      bottom: 8.0,
                    ),
                    child: Text('- ${e.getSafeTitle()}'),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(
                      left: kPadding,
                    ),
                    child: Text(e.description ?? ''),
                  ),
                );
              },
            ),
          const HorizontalLine(),
        ],
      ),
    );
  }
}
