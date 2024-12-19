import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_color_theme.dart';
import 'package:flutter/cupertino.dart';

const _dividerHeight = .3;

class EdgeLine extends StatelessWidget {
  const EdgeLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _dividerHeight,
      width: double.infinity,
      color: CustomColorTheme.of(context).normalTextColor.withOpacity(.2),
    );
  }
}
