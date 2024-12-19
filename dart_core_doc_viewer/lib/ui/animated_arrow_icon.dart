import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_color_theme.dart';
import 'package:flutter/material.dart';

class AnimatedArrowIcon extends StatelessWidget {
  const AnimatedArrowIcon({
    required this.isOpen,
    super.key,
  });

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: isOpen ? -.25 : .25,
      curve: Curves.linear,
      duration: kThemeAnimationDuration,
      child: Icon(
        Icons.arrow_forward_ios,
        color: CustomColorTheme.of(context).normalTextColor,
        size: 16.0,
      ),
    );
  }
}
