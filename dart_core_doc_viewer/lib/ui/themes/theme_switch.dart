import 'package:dart_core_doc_viewer/controllers/theme_controller.dart';
import 'package:dart_core_doc_viewer/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:lite_state/lite_state.dart';

class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return LiteState<ThemeController>(
      builder: (BuildContext c, ThemeController controller) {
        return Switch(
          activeThumbImage: AssetImage(
            'moon'.toPngIconPath(),
          ),
          inactiveThumbImage: AssetImage(
            'sun'.toPngIconPath(),
          ),
          value: themeController.isDarkTheme,
          onChanged: (value) {
            themeController.toggleTheme();
          },
        );
      },
    );
  }
}
