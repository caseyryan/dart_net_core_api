import 'package:dart_core_doc_viewer/controllers/main_page_controller.dart';
import 'package:dart_core_doc_viewer/main_page/widgets/response_list.dart';
import 'package:dart_core_doc_viewer/ui/vertical_line.dart';
import 'package:flutter/material.dart';

import 'group_list.dart';

class WideScreenLayout extends StatelessWidget {
  const WideScreenLayout({
    super.key,
    required this.controller,
  });

  final MainPageController controller;

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          flex: 30,
          child: GroupList(),
        ),
        SizedBox(
          height: 3.0,
        ),
        VerticalLine(),
        Expanded(
          flex: 80,
          child: ResponseList(),
        ),
      ],
    );
  }
}
