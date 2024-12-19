import 'package:dart_core_doc_viewer/constants.dart';
import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_color_theme.dart';
import 'package:flutter/cupertino.dart';


class HorizontalLine extends StatelessWidget {
  const HorizontalLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kDividerThickness,
      width: double.infinity,
      color: CustomColorTheme.of(context).normalTextColor.withOpacity(.2),
    );
  }
}
