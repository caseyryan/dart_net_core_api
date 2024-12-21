import 'package:dart_core_doc_viewer/constants.dart';
import 'package:dart_core_doc_viewer/extensions/map_extensions.dart';
import 'package:dart_core_doc_viewer/main_page/widgets/json_block.dart';
import 'package:dart_core_doc_viewer/ui/text/description.dart';
import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:lite_forms/base_form_fields/label.dart';
import 'package:lite_forms/lite_forms.dart';

import '../../api/response_models/documentation_response/api_endpoint_model.dart';
import 'highlighted_wrapper.dart';

class ParametersView extends StatefulWidget {
  const ParametersView({
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

  final ApiEndpointModel model;

  @override
  State<ParametersView> createState() => _ParametersViewState();
}

class _ParametersViewState extends State<ParametersView> {
  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Description(
        text: 'Request parameters:',
        paddingBottom: kPadding,
        style: CustomTextTheme.of(context).boldStyle,
      ),
    ];
    if (widget.model.params?.isNotEmpty != true) {
      children.add(
        const SizedBox(
          width: double.infinity,
          child: Description(
            text: 'This endpoint has no parameters.',
          ),
        ),
      );
    } else {
      for (var param in widget.model.params!) {
        if (param.isBodyParam == true) {
          if (param.type is Map) {
            children.add(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Label(text: 'Body:'),
                  JsonBlock(
                    code: (param.type! as Map).toFormattedJson(),
                  ),
                ],
              ),
            );
          }
        } else {
          String paramLabel = param.name!;
          if (param.isRequired != true) {
            paramLabel = '$paramLabel (optional)';
          }
          children.add(
            Row(
              children: [
                Expanded(
                  child: LiteTextFormField(
                    name: param.name!,
                    label: paramLabel,
                    hintText: param.name!.firstToUpperCase(),
                    paddingBottom: kPadding,
                  ),
                ),
                const Spacer(),
              ],
            ),
          );
        }
      }
    }
    return Padding(
      padding: EdgeInsets.only(
        top: widget.paddingTop,
        bottom: widget.paddingBottom,
        left: widget.paddingLeft,
        right: widget.paddingRight,
      ),
      child: HighlightedWrapper(
        child: LiteForm(
          name: 'form${widget.model.method}${widget.model.path}',
          builder: (c, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            );
          },
        ),
      ),
    );
  }
}
