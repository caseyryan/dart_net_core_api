// ignore_for_file: depend_on_referenced_packages

import 'package:dart_core_doc_viewer/constants.dart';
import 'package:dart_core_doc_viewer/controllers/theme_controller.dart';
import 'package:dart_core_doc_viewer/ui/buttons/copy_button.dart';
import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlighting/flutter_highlighting.dart';
import 'package:flutter_highlighting/themes/github-dark-dimmed.dart';
import 'package:flutter_highlighting/themes/github.dart';
import 'package:highlighting/languages/dart.dart';
import 'package:lite_state/lite_state.dart';

class DartBlock extends StatelessWidget {
  const DartBlock({
    super.key,
    required this.code,
  });

  final String code;

  @override
  Widget build(BuildContext context) {
    return LiteState<ThemeController>(
      builder: (BuildContext c, ThemeController controller) {
        final colorTheme = Map<String, TextStyle>.from(themeController.isDarkTheme ? githubDarkDimmedTheme : githubTheme);
        final bgColor = colorTheme['root']!.backgroundColor as Color;
        colorTheme['root'] = colorTheme['root']!.copyWith(
          backgroundColor: Colors.transparent,
        );
        return Material(
          color: bgColor,
          child: SizedBox(
            width: double.infinity,
            child: Stack(
              children: [
                HighlightView(
                  code,
                  languageId: dart.id,
                  theme: colorTheme,
                  padding: const EdgeInsets.all(kPadding),
                  textStyle: CustomTextTheme.of(context).defaultStyle,
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: CopyButton(
                    text: code,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
