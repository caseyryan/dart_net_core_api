import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_text_theme.dart';
import 'package:flutter/material.dart';

/// A Caption is simple text already styled as a caption
/// Use it where ever you need a 13pt regular text with Label/Primary color
class Caption extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;
  final Color? textColor;
  final bool isSliver;

  const Caption({
    required this.text,
    this.textAlign,
    this.paddingTop = 0.0,
    this.paddingBottom = 0.0,
    this.paddingLeft = 0.0,
    this.paddingRight = 0.0,
    this.textColor,
    this.isSliver = false,
    super.key,
  });

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
        style: theme.captionStyle.copyWith(
          color: textColor,
        ),
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
