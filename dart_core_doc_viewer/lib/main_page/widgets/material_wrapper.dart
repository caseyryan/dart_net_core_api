import 'package:dart_core_doc_viewer/constants.dart';
import 'package:flutter/material.dart';

class MaterialWrapper extends StatelessWidget {
  const MaterialWrapper({
    super.key,
    required this.child,
    this.paddingTop = 0.0,
    this.paddingBottom = 0.0,
    this.paddingLeft = 0.0,
    this.paddingRight = 0.0,
  });

  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: paddingTop,
        bottom: paddingBottom,
        left: paddingLeft,
        right: paddingRight,
      ),
      child: Material(
        elevation: kMaterialElevation,
        child: Padding(
          padding: const EdgeInsets.all(
            kPadding,
          ),
          child: child,
        ),
      ),
    );
  }
}
