import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_text_theme.dart';
import 'package:flutter/material.dart';

/// A Description is simple text
/// Use it where ever you need a 17pt regular text with Label/Primary color
class Description extends StatelessWidget {
  const Description({
    required this.text,
    this.textAlign,
    this.paddingTop = 0.0,
    this.paddingBottom = 0.0,
    this.paddingLeft = 0.0,
    this.paddingRight = 0.0,
    this.isSliver = false,
    this.style,
    super.key,
  });

  final String text;
  final TextAlign? textAlign;
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;
  final bool isSliver;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = CustomTextTheme.of(context);
    final child = Padding(
      padding: EdgeInsets.only(
        top: paddingTop,
        bottom: paddingBottom,
        left: paddingLeft,
        right: paddingRight,
      ),
      child: Text(
        text,
        style: style ?? theme.descriptionStyle,
        textAlign: textAlign,
      ),
    );
    if (isSliver) {
      return SliverToBoxAdapter(
        child: child,
      );
    }
    return child;
  }
}
