import 'package:flutter/material.dart';
import 'package:lite_state/lite_state.dart';

import '../controllers/main_page_controller.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final MainPageController _controller = MainPageController();

  @override
  Widget build(BuildContext context) {
    return LiteState<MainPageController>(
      controller: _controller,
      onReady: (MainPageController controller) {
        controller.loadDocumentation();
      },
      builder: (BuildContext c, MainPageController controller) {
        return Scaffold(
          appBar: AppBar(),
        );
      },
    );
  }
}
