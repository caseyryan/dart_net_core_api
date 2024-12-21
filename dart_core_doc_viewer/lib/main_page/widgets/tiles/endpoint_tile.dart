import 'package:dart_core_doc_viewer/api/response_models/documentation_response/api_endpoint_model.dart';
import 'package:dart_core_doc_viewer/constants.dart';
import 'package:dart_core_doc_viewer/main_page/widgets/highlighted_wrapper.dart';
import 'package:dart_core_doc_viewer/ui/animated_arrow_icon.dart';
import 'package:dart_core_doc_viewer/ui/horizontal_line.dart';
import 'package:dart_core_doc_viewer/ui/text/caption.dart';
import 'package:dart_core_doc_viewer/ui/text/description.dart';
import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_color_theme.dart';
import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_text_theme.dart';
import 'package:flutter/material.dart';

import '../parameters_view.dart';
import '../response_view.dart';

class EndpointTile extends StatefulWidget {
  const EndpointTile({
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
  State<EndpointTile> createState() => _EndpointTileState();
}

class _EndpointTileState extends State<EndpointTile> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: widget.paddingTop,
        bottom: widget.paddingBottom,
        left: widget.paddingLeft,
        right: widget.paddingRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            onTap: () {
              setState(() {
                widget.model.isExpanded = !widget.model.isExpanded;
              });
            },
            selected: widget.model.isExpanded,
            selectedTileColor: widget.model.isExpanded ? CustomColorTheme.of(context).paleBackgroundColor : null,
            leading: _MethodIcon(
              method: widget.model.method!.toUpperCase(),
              key: Key(widget.model.method!),
            ),
            title: Padding(
              padding: const EdgeInsets.only(
                bottom: kPadding,
              ),
              child: Text(widget.model.path!),
            ),
            subtitle: Caption(text: widget.model.description ?? ''),
            trailing: AnimatedArrowIcon(
              isOpen: widget.model.isExpanded,
            ),
          ),
          if (widget.model.isExpanded) ...[
            ParametersView(
              paddingTop: 0.0,
              paddingBottom: 0.0,
              paddingLeft: 0.0,
              paddingRight: 0.0,
              key: Key(
                'params_view_${widget.model.method!.toUpperCase()}',
              ),
              model: widget.model,
            ),
            HighlightedWrapper(
              child: Description(
                text: 'Responses examples:',
                style: CustomTextTheme.of(context).boldStyle,
              ),
            ),
            ...widget.model.responseModels!.map(
              (e) {
                return ResponseView(
                  paddingBottom: 0.0,
                  paddingTop: 0.0,
                  paddingLeft: 0.0,
                  paddingRight: 0.0,
                  key: ValueKey(e),
                  model: e,
                );
              },
            ),
          ],
          const HorizontalLine(),
        ],
      ),
    );
  }
}

class _MethodIcon extends StatelessWidget {
  const _MethodIcon({
    super.key,
    required this.method,
  });

  final String method;

  Color? _getTextColor(
    BuildContext context,
  ) {
    final colorTheme = CustomColorTheme.of(context);
    switch (method) {
      case 'GET':
        return colorTheme.positiveColor;
      case 'POST':
      case 'PUT':
      case 'PATCH':
        return colorTheme.warningColor;
      case 'DELETE':
        return colorTheme.negativeColor;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SizedBox(
        width: 70.0,
        height: 70.0,
        child: Center(
          child: Text(
            method,
            style: CustomTextTheme.of(context)
                .defaultStyle
                .copyWith(color: _getTextColor(context), fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
