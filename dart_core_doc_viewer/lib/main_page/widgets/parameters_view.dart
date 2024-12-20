import 'package:dart_core_doc_viewer/ui/text/description.dart';
import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_color_theme.dart';
import 'package:flutter/material.dart';
import 'package:lite_forms/lite_forms.dart';

import '../../api/response_models/documentation_response/api_endpoint_model.dart';

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
    final children = <Widget>[];
    if (widget.model.params?.isNotEmpty != true) {
      children.add(
        const Description(
          text: 'This endpoint has no parameters.',
        ),
      );
    } else {
      for (var param in widget.model.params!) {
        if (param.isBodyParam == true) {
          print(param.type);
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
      child: Material(
        color: CustomColorTheme.of(context).paleBackgroundColor,
        child: LiteForm(
          name: 'form${widget.model.method}${widget.model.path}',
          builder: (c, scrollController) {
            return Column(
              children: children,
            );
          },
        ),
      ),
    );
  }
}
