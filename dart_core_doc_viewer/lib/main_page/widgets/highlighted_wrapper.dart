import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_color_theme.dart';
import 'package:flutter/material.dart';

class HighlightedWrapper extends StatelessWidget {
  const HighlightedWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CustomColorTheme.of(context).wordHighlightColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: double.infinity,
          child: child,
        ),
      ),
    );
  }
}
