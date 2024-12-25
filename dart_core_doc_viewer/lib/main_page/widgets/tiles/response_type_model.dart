import 'package:dart_core_doc_viewer/constants.dart';
import 'package:dart_core_doc_viewer/main_page/widgets/dart_block.dart';
import 'package:flutter/material.dart';

class ResponseTypeModel extends StatelessWidget {
  const ResponseTypeModel({
    super.key,
    required this.text,
    this.paddingTop = 0.0,
    this.paddingBottom = 0.0,
    this.paddingLeft = 0.0,
    this.paddingRight = 0.0,
  });

  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;
  final String text;

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
        child: DartBlock(
          code: text,
        ),
      ),
    );
  }
}
