import 'package:dart_core_doc_viewer/constants.dart';
import 'package:dart_core_doc_viewer/controllers/on_page_info_controller.dart';
import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_color_theme.dart';
import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:lite_state/lite_state.dart';

enum OnPageInfoStyle {
  info,
  warning,
}

class OnPageInfo extends StatefulWidget {
  const OnPageInfo({
    super.key,
    required this.text,
    required this.name,
    this.paddingTop = 0.0,
    this.paddingBottom = 0.0,
    this.paddingLeft = 0.0,
    this.paddingRight = 0.0,
    this.textAlign = TextAlign.left,
    this.textColor,
    this.infoStyle = OnPageInfoStyle.info,
    this.maxLines = 20,
    this.textOverflow,
    this.isDismissible = true,
    this.isSliver = false,
  });

  final String name;
  final String text;
  final bool isSliver;
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;
  final TextAlign textAlign;
  final Color? textColor;
  final int maxLines;
  final TextOverflow? textOverflow;
  final OnPageInfoStyle infoStyle;
  final bool isDismissible;

  @override
  State<OnPageInfo> createState() => _OnPageInfoState();
}

class _OnPageInfoState extends State<OnPageInfo> {
  @override
  void initState() {
    initControllers({
      OnPageInfoController: () => OnPageInfoController(),
    });
    super.initState();
  }

  TextStyle _getTextStyle(BuildContext context) {
    var style = CustomTextTheme.of(context).descriptionStyle;
    if (widget.textColor != null) {
      style = style.copyWith(color: widget.textColor);
    }
    return style;
  }

  Color _getColor(BuildContext context) {
    if (widget.infoStyle == OnPageInfoStyle.info) {
      return CustomColorTheme.of(context).positiveColor;
    } else if (widget.infoStyle == OnPageInfoStyle.warning) {
      return CustomColorTheme.of(context).warningColor;
    }
    return CustomColorTheme.of(context).paleBackgroundColor;
  }

  Widget _buildCloseButton(BuildContext context) {
    if (!widget.isDismissible) {
      return const SizedBox.shrink();
    }
    return Positioned(
      right: 3.0,
      top: 3.0,
      child: SizedBox(
        width: 20.0,
        height: 20.0,
        child: MaterialButton(
          padding: const EdgeInsets.all(0),
          onPressed: () {
            onPageInfoController.dismiss(widget.name);
          },
          child: Icon(
            Icons.close,
            size: 16.0,
            color: CustomTextTheme.of(context).descriptionStyle.color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiteState<OnPageInfoController>(
      builder: (BuildContext c, OnPageInfoController controller) {
        if (controller.isDismissed(widget.name)) {
          if (widget.isSliver) {
            return const SliverToBoxAdapter();
          }
          return const SizedBox.shrink();
        }
        final style = _getTextStyle(context);

        final child = SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.only(
              top: widget.paddingTop,
              left: widget.paddingLeft,
              right: widget.paddingRight,
              bottom: widget.paddingBottom,
            ),
            child: CustomPaint(
              painter: _InfoPainter(
                backgroundColor: _getColor(context).withOpacity(.1),
                sideLineColor: _getColor(context),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: kPadding,
                      right: kPadding + 8.0,
                      bottom: kPadding,
                      left: kPadding + 8.0,
                    ),
                    child: Text(
                      widget.text,
                      style: style,
                      textAlign: widget.textAlign,
                      maxLines: widget.maxLines,
                      overflow: widget.textOverflow ?? TextOverflow.ellipsis,
                    ),
                  ),
                  _buildCloseButton(context),
                ],
              ),
            ),
          ),
        );
        if (widget.isSliver) {
          return SliverToBoxAdapter(
            child: child,
          );
        }
        return child;
      },
    );
  }
}

class _InfoPainter extends CustomPainter {
  final Color sideLineColor;
  final Color backgroundColor;

  late Paint _bgPaint;
  late Paint _sideLinePaint;

  _InfoPainter({
    required this.sideLineColor,
    required this.backgroundColor,
  }) {
    _bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    _sideLinePaint = Paint()
      ..color = sideLineColor
      ..style = PaintingStyle.fill;
  }

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    const radius = 5.0;
    const lineWidth = 5.0;
    canvas.drawRRect(
      RRect.fromLTRBR(
        0.0,
        0.0,
        lineWidth,
        size.height,
        const Radius.circular(radius),
      ),
      _sideLinePaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(
        lineWidth * .5,
        0.0,
        lineWidth,
        size.height,
      ),
      _sideLinePaint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(
        5.0,
        0.0,
        size.width,
        size.height,
        const Radius.circular(radius),
      ),
      _bgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _InfoPainter oldDelegate) {
    return true;
  }
}
