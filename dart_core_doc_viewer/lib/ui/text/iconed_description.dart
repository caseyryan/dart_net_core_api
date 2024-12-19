import 'package:dart_core_doc_viewer/ui/text/description.dart';
import 'package:flutter/cupertino.dart';

class IconedDescription extends StatelessWidget {
  const IconedDescription({
    required this.text,
    required this.leadingIcon,
    this.paddingTop = 0.0,
    this.paddingBottom = 0.0,
    this.paddingLeft = 0.0,
    this.paddingRight = 0.0,
    this.isSliver = false,
    this.style,
    super.key,
  });

  final String text;
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;
  final bool isSliver;
  final TextStyle? style;
  final Widget leadingIcon;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: EdgeInsets.only(
        top: paddingTop,
        bottom: paddingBottom,
        left: paddingLeft,
        right: paddingRight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              right: 6.0,
              top: 6.0
            ),
            child: leadingIcon,
          ),
          Expanded(
            child: Description(
              text: text,
              style: style,
            ),
          )
        ],
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
