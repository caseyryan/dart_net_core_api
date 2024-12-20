import 'package:dart_core_doc_viewer/main_page/widgets/wide_screen_layout.dart';
import 'package:flutter/material.dart';
import 'package:lite_state/lite_state.dart';

import '../controllers/main_page_controller.dart';

class MainPage extends StatefulWidget {
  static const String routeName = 'MainPage';

  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return LiteState<MainPageController>(
      onReady: (MainPageController controller) {
        controller.loadDocumentation();
      },
      builder: (BuildContext c, MainPageController controller) {
        return WideScreenLayout(
          controller: controller,
        );
      },
    );
  }
}
