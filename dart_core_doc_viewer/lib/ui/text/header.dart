import 'package:dart_core_doc_viewer/constants.dart';
import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_text_theme.dart';
import 'package:flutter/material.dart';

/// A header is simple text already styled as a header.
/// Use it where ever you need a 20pt/24pt bold text with Label/Primary color
class Header extends StatelessWidget {
  final String? text;
  final TextAlign? textAlign;
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;
  final bool isBigHeader;
  final Color? textColor;
  final bool isSliver;

  /// [isBigHeader] will use a header style with 24pt font size
  const Header({
    required this.text,
    this.textAlign,
    this.isBigHeader = false,
    this.isSliver = false,
    this.paddingTop = kPadding,
    this.paddingBottom = kPadding,
    this.paddingLeft = 0.0,
    this.paddingRight = 0.0,
    this.textColor,
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
        text ?? '',
        style: isBigHeader
            ? theme.mainWordStyle.copyWith(
                color: textColor,
              )
            : theme.headerStyle.copyWith(
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
