// ignore_for_file: library_private_types_in_public_api

import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_text_theme.dart';
import 'package:flutter/material.dart';

import 'themes/theme_extensions/custom_color_theme.dart';

class AnimatedHorizontalToggler extends StatefulWidget {
  final int buttonIndex;
  final List<String> labels;
  final ValueChanged<int>? onIndexChanged;
  final List<Widget>? overlayLabels;
  final double height;
  final double borderRadius;

  AnimatedHorizontalToggler({
    super.key,
    required this.buttonIndex,
    required this.onIndexChanged,
    required this.labels,
    this.height = 32,
    this.borderRadius = 7.0,
    this.overlayLabels,
    this.paddingTop = 0.0,
    this.paddingBottom = 0.0,
    this.paddingLeft = 0.0,
    this.paddingRight = 0.0,
  }) {
    if (overlayLabels != null) {
      assert(overlayLabels!.length == labels.length);
    }
  }

  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;

  @override
  _AnimatedHorizontalTogglerState createState() => _AnimatedHorizontalTogglerState();
}

class _AnimatedHorizontalTogglerState extends State<AnimatedHorizontalToggler> {
  double? _buttonWidth;
  int _activeTabIndex = 0;
  double? _buttonPosition;
  final double _padding = 0.0;
  final double _borderWidth = 0.5;

  @override
  void initState() {
    super.initState();
    _updateIndex();
  }

  @override
  void didUpdateWidget(covariant AnimatedHorizontalToggler oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateIndex();
  }

  void _updateIndex() {
    if (_buttonWidth == null) {
      return;
    }
    if (_activeTabIndex == widget.buttonIndex) {
      return;
    }
    _activeTabIndex = widget.buttonIndex;
    if (_activeTabIndex >= widget.labels.length) {
      _activeTabIndex = 0;
      widget.onIndexChanged?.call(_activeTabIndex);
    }
    _buttonPosition = _activeTabIndex * _buttonWidth!;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildOverlayLabel(int index) {
    if (widget.overlayLabels != null) {
      return widget.overlayLabels![index];
    }
    return const SizedBox.shrink();
  }

  List<Widget> _getLabels() {
    var children = <Widget>[];
    for (var i = 0; i < widget.labels.length; i++) {
      var isActive = i == _activeTabIndex;
      children.add(
        SizedBox(
          width: _buttonWidth,
          height: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Text(
                  widget.labels[i],
                  style: CustomTextTheme.of(context).defaultStyle.copyWith(
                        fontWeight: isActive ? FontWeight.w500 : null,
                      ),
                ),
              ),
              Positioned(
                right: 4.0,
                top: 4.0,
                child: _buildOverlayLabel(i),
              ),
            ],
          ),
        ),
      );
    }
    return children;
  }

  List<Widget> _getSeparators() {
    var children = <Widget>[];
    for (var i = 0; i < widget.labels.length - 1; i++) {
      children.add(
        SizedBox(
          width: _buttonWidth!,
          height: double.infinity,
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              Container(
                height: widget.height * .5,
                width: _borderWidth,
                color: const Color(0xff3c3c43).withOpacity(0.0),
              ),
            ],
          ),
        ),
      );
    }
    return children;
  }

  ShapeBorder _getShape() {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
        widget.borderRadius,
      ),
      side: BorderSide(
        width: _borderWidth,
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const padding = 2.0;
    return Padding(
      padding: EdgeInsets.only(
        left: widget.paddingLeft,
        right: widget.paddingRight,
        top: widget.paddingTop,
        bottom: widget.paddingBottom,
      ),
      child: SizedBox(
        width: double.infinity,
        height: widget.height,
        child: LayoutBuilder(
          builder: (c, BoxConstraints constraints) {
            _buttonWidth = constraints.biggest.width / widget.labels.length;
            if (_buttonPosition == null) {
              _updateIndex();
            }
            final widthIncrease = (_activeTabIndex > 0 ? _borderWidth : 0.0);
            return GestureDetector(
              onTapUp: (TapUpDetails details) {
                setState(() {
                  _activeTabIndex = (details.localPosition.dx / _buttonWidth!).floor();
                  widget.onIndexChanged?.call(
                    _activeTabIndex,
                  );
                });
              },
              child: Material(
                shape: _getShape(),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: SizedBox(
                  width: double.infinity,
                  height: widget.height,
                  child: Stack(
                    children: [
                      IgnorePointer(
                        child: Row(
                          children: _getSeparators(),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: kThemeAnimationDuration,
                        curve: Curves.easeInOutQuint,
                        left: _activeTabIndex * _buttonWidth! - widthIncrease,
                        top: 0.0,
                        child: IgnorePointer(
                          child: Padding(
                            padding: const EdgeInsets.all(padding),
                            child: Material(
                              elevation: 0.0,
                              shape: _getShape(),
                              color: CustomColorTheme.of(context).paleBackgroundColor,
                              child: SizedBox(
                                width: ((_buttonWidth! - (1 * (widget.labels.length))) -
                                        _padding * padding +
                                        widthIncrease) -
                                    padding,
                                height: widget.height - padding * 2.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: Row(
                          children: _getLabels(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
