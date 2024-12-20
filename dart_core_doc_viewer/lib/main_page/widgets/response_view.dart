import 'package:dart_core_doc_viewer/api/response_models/documentation_response/response_model.dart';
import 'package:dart_core_doc_viewer/constants.dart';
import 'package:dart_core_doc_viewer/extensions/map_extenstions.dart';
import 'package:dart_core_doc_viewer/main_page/widgets/json_block.dart';
import 'package:dart_core_doc_viewer/ui/text/description.dart';
import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_color_theme.dart';
import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_text_theme.dart';
import 'package:flutter/material.dart';

class ResponseView extends StatelessWidget {
  const ResponseView({
    super.key,
    required this.model,
    this.paddingTop = 0.0,
    this.paddingBottom = 0.0,
    this.paddingLeft = 0.0,
    this.paddingRight = 0.0,
  });

  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;

  final ResponseModel? model;

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
        // elevation: .1,
        color: CustomColorTheme.of(context).paleBackgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Flexible(
                  child: Description(
                    text: 'Status Code:',
                    style: CustomTextTheme.of(context).boldStyle,
                    paddingLeft: kPadding,
                    paddingBottom: kPadding,
                    paddingTop: kPadding,
                    paddingRight: 0.0,
                  ),
                ),
                Description(
                  text: ' ${model!.statusCode}',
                  style: CustomTextTheme.of(context).boldStyle!.copyWith(
                        color: model!.isSuccess
                            ? CustomColorTheme.of(context).positiveColor
                            : CustomColorTheme.of(context).negativeColor,
                      ),
                  paddingLeft: 4.0,
                  paddingBottom: kPadding,
                  paddingTop: kPadding,
                  paddingRight: kPadding,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: JsonBlock(
                code: model!.response!.toFormattedJson(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
