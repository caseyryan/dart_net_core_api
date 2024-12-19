import 'package:flutter/material.dart';

import '../constants.dart';
import 'animated_arrow_icon.dart';
import 'themes/theme_extensions/custom_color_theme.dart';

class OnPageExpandable extends StatefulWidget {
  const OnPageExpandable({
    super.key,
    this.minHeight = kButtonHeight,
    required this.headerChild,
    this.innerChild,
    this.isExpanded = false,
    this.hasBottomBorder = false,
    this.arrowPaddingRight = kPadding,
    this.arrowPaddingLeft = kPadding,
    this.onChange,
    this.paddingTop = 0.0,
    this.paddingBottom = 0.0,
    this.paddingLeft = 0.0,
    this.paddingRight = 0.0,
    this.reverseIconRotation = false,
    this.backgroundColor,
  });

  final double minHeight;
  final bool isExpanded;
  final bool hasBottomBorder;
  final double arrowPaddingRight;
  final double arrowPaddingLeft;
  final ValueChanged<bool>? onChange;
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;
  final bool reverseIconRotation;
  final Color? backgroundColor;

  /// [headerChild] is the part user can always see
  final Widget headerChild;

  /// [innerChild] is the part that will be displayed when
  /// you expand the tile. If you pass null here, the tile
  /// will not display "expand" chevron
  final Widget? innerChild;

  @override
  State<OnPageExpandable> createState() => _OnPageExpandableState();
}

class _OnPageExpandableState extends State<OnPageExpandable> {
  bool _isExpanded = false;

  @override
  void initState() {
    _isExpanded = widget.isExpanded;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant OnPageExpandable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      setState(() {
        if (widget.innerChild == null) {
          _isExpanded = false;
        } else {
          _isExpanded = widget.isExpanded;
        }
      });
    }
  }

  VoidCallback? _getOnTapFunction() {
    if (widget.innerChild != null) {
      return _onTap;
    }

    return null;
  }

  void _onTap() {
    widget.onChange?.call(!_isExpanded);
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: widget.paddingTop,
        bottom: widget.paddingBottom,
        left: widget.paddingLeft,
        right: widget.paddingRight,
      ),
      child: Material(
        color: widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            kBorderRadius,
          ),
        ),
        child: InkWell(
          splashColor: Colors.transparent,
          onTap: _getOnTapFunction(),
          child: Container(
            decoration: widget.hasBottomBorder
                ? BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 0.5,
                        color: CustomColorTheme.of(context).normalTextColor.withOpacity(0.2),
                      ),
                    ),
                  )
                : null,
            constraints: BoxConstraints(
              minHeight: widget.minHeight,
            ),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        alignment: Alignment.centerLeft,
                        constraints: BoxConstraints(
                          minHeight: widget.minHeight,
                        ),
                        child: widget.headerChild,
                      ),
                    ),
                    if (widget.innerChild != null)
                      Padding(
                        padding: EdgeInsets.only(
                          left: widget.arrowPaddingLeft,
                          right: widget.arrowPaddingRight,
                        ),
                        child: AnimatedArrowIcon(
                          isOpen: widget.reverseIconRotation ? !_isExpanded : _isExpanded,
                        ),
                      ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: AnimatedSize(
                    duration: kThemeAnimationDuration,
                    alignment: Alignment.bottomLeft,
                    child: _isExpanded ? widget.innerChild : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
