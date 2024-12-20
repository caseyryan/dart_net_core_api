import 'package:dart_core_doc_viewer/api/response_models/documentation_response/controller_api_model.dart';
import 'package:dart_core_doc_viewer/constants.dart';
import 'package:dart_core_doc_viewer/main_page/widgets/group_list.dart';
import 'package:dart_core_doc_viewer/ui/animated_arrow_icon.dart';
import 'package:dart_core_doc_viewer/ui/horizontal_line.dart';
import 'package:dart_core_doc_viewer/ui/text/caption.dart';
import 'package:dart_core_doc_viewer/ui/text/header.dart';
import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_color_theme.dart';
import 'package:flutter/material.dart';

class ApiGroupTile extends StatelessWidget {
  const ApiGroupTile({
    super.key,
    required this.groupData,
    required this.onExpandToggle,
    required this.onControllerSelected,
    required this.selectedController,
  });

  final ValueChanged<GroupData> onExpandToggle;
  final ValueChanged<ControllerApiModel> onControllerSelected;
  final ControllerApiModel? selectedController;

  final GroupData groupData;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          ListTile(
            title: Header(
              text: groupData.group.title,
            ),
            selected: groupData.controllers.contains(selectedController),
            trailing: AnimatedArrowIcon(
              isOpen: groupData.isExpanded,
            ),
            onTap: () {
              onExpandToggle(groupData);
            },
          ),
          if (groupData.isExpanded)
            ...groupData.controllers.map(
              (e) {
                return ListTile(
                  selectedTileColor: CustomColorTheme.of(context).paleBackgroundColor,
                  selected: e == selectedController,
                  key: ValueKey(e),
                  onTap: () {
                    onControllerSelected(e);
                  },
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
                    child: Caption(
                      text: e.getSafeDescription(),
                    ),
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
