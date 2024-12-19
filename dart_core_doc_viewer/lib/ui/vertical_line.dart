import 'package:dart_core_doc_viewer/constants.dart';
import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_color_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class VerticalLine extends StatelessWidget {
  const VerticalLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kDividerThickness,
      height: double.infinity,
      color: CustomColorTheme.of(context).normalTextColor.withOpacity(.5),
    );
  }
}
