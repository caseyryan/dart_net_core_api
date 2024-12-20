import 'dart:async';
import 'dart:math';

import 'package:dart_core_doc_viewer/main.dart';
import 'package:dart_core_doc_viewer/ui/text/description.dart';
import 'package:dart_core_doc_viewer/ui/text/header.dart';
import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_color_theme.dart';
import 'package:dart_core_doc_viewer/ui/themes/theme_utils.dart';
import 'package:dart_core_doc_viewer/utils/screen_utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lite_forms/base_form_fields/mixins/post_frame_mixin.dart';
import 'package:lite_forms/utils/swipe_detector.dart';

import '../constants.dart';

GlobalKey<_SnackbarOverlayState> _globalKey = GlobalKey();


bool? showErrorFromMap(Map data) {
  if (data.containsKey('message')) {
    showError(text: data['message']);
    return true;
  }
  return null;
}

void showError({
  String title = '',
  required String text,
}) {
  _showMessage(
    text: text,
    title: title.isNotEmpty ? title : 'Произошла ошибка',
    type: SnackbarType.error,
  );
}

void showInformation({
  String title = '',
  required String text,
}) {
  _showMessage(
    text: text,
    title: title.isNotEmpty ? title : 'Информация',
    type: SnackbarType.info,
  );
}

void showSuccess({
  String title = '',
  required String text,
}) {
  _showMessage(
    text: text,
    title: title.isNotEmpty ? title : 'Успешно!',
    type: SnackbarType.success,
  );
}

void _showMessage({
  required String title,
  required String text,
  required SnackbarType type,
}) {
  int millis = min((title.length + text.length) * 100, 5000);
  // millis = 1000000;
  _globalKey.currentState?._addMessage(
    SnackbarData(
      durationMillis: millis,
      title: title,
      text: text,
      type: type,
    ),
  );
}

class SnackbarOverlay extends StatelessWidget {
  const SnackbarOverlay({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _SnackbarOverlay(
      key: _globalKey,
    );
  }
}

class _SnackbarOverlay extends StatefulWidget {
  const _SnackbarOverlay({super.key});

  @override
  State<_SnackbarOverlay> createState() => _SnackbarOverlayState();
}

class _SnackbarOverlayState extends State<_SnackbarOverlay> {
  final List<SnackbarData> _datas = [];
  static const int _maxMessagesOnScreen = 3;
  static const int _maxMessagesInBuffer = 6;

  void _addMessage(SnackbarData data) {
    setState(() {
      if (_datas.length >= _maxMessagesInBuffer) {
        _datas.removeAt(0);
      }
      _datas.add(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return SizedBox(
      width: mediaQuery.size.width,
      height: mediaQuery.size.height,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(kPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: _datas
                .take(_maxMessagesOnScreen)
                .map(
                  (e) => SnackbarView(
                    key: ValueKey(e),
                    paddingTop: kPadding,
                    onComplete: ((value) {
                      setState(() {
                        _datas.remove(value);
                      });
                    }),
                    data: e,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

enum SnackbarType {
  error,
  success,
  info,
}

class SnackbarData {
  SnackbarType type;
  String title;
  String text;
  int durationMillis;
  int _millisAccumulated = 0;

  double get _progress {
    return (_millisAccumulated / durationMillis).clamp(0.0, 1.0);
  }

  bool get _isComplete {
    return _millisAccumulated >= durationMillis;
  }

  SnackbarData({
    required this.type,
    required this.title,
    required this.text,
    required this.durationMillis,
  });
}

class SnackbarView extends StatefulWidget {
  final SnackbarData data;
  final ValueChanged<SnackbarData> onComplete;
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;

  const SnackbarView({
    super.key,
    required this.data,
    required this.onComplete,
    this.paddingTop = 0.0,
    this.paddingBottom = 0.0,
    this.paddingLeft = 0.0,
    this.paddingRight = 0.0,
  });

  @override
  State<SnackbarView> createState() => _SnackbarViewState();
}

class _SnackbarViewState extends State<SnackbarView> with SingleTickerProviderStateMixin, PostFrameMixin {
  late Timer _timer;
  late AnimationController _animationController;
  late Animation<double> _appearAnimation;
  late Animation<double> _sizeAnimation;
  static const int _millis = 500;
  static const double _sizeTimeOffset = .35;
  final GlobalKey _sizeKey = GlobalKey();
  double _height = 0.0;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _millis),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _appearAnimation = Tween<double>(
      begin: -_maxOffset,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(
          _sizeTimeOffset,
          1.0,
          curve: Curves.easeOutExpo,
        ),
      ),
    );
    _createSizeAnimation();

    _timer = Timer.periodic(
      const Duration(milliseconds: 20),
      (timer) {
        if (_animationController.status == AnimationStatus.completed) {
          widget.data._millisAccumulated += 20;
          if (widget.data._isComplete) {
            _timer.cancel();
            _complete();
          }
          setState(() {});
        }
      },
    );
    super.initState();
    _animationController.forward();
  }

  void _createSizeAnimation() {
    _sizeAnimation = Tween<double>(
      begin: 0.0,
      end: _height,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(
          0.0,
          _sizeTimeOffset,
          curve: Curves.linear,
        ),
      ),
    );
  }

  Future _complete() async {
    await _animationController.reverse();
    widget.onComplete(widget.data);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer.cancel();
    super.dispose();
  }

  double get _width {
    return isNarrowScreen ? screenWidthScaled : 400.0;
  }

  Color get _color {
    if (widget.data.type == SnackbarType.error) {
      return CustomColorTheme.of(context).negativeColor;
    }
    if (widget.data.type == SnackbarType.success) {
      return CustomColorTheme.of(context).positiveColor;
    }
    if (widget.data.type == SnackbarType.info) {
      return CustomColorTheme.of(context).warningColor;
    }
    return Colors.transparent;
  }

  Widget _buildIcon() {
    if (widget.data.type == SnackbarType.error) {
      return FaIcon(
        FontAwesomeIcons.solidFaceSadTear,
        color: _color,
        size: 24.0,
      );
    }
    if (widget.data.type == SnackbarType.success) {
      return FaIcon(
        FontAwesomeIcons.solidFaceSmile,
        color: _color,
        size: 24.0,
      );
    }
    if (widget.data.type == SnackbarType.info) {
      return FaIcon(
        FontAwesomeIcons.circleInfo,
        color: _color,
        size: 24.0,
      );
    }
    return const SizedBox.shrink();
  }

  double get _maxOffset {
    return _width + kPadding;
  }

  @override
  void didFirstLayoutFinished(BuildContext context) {
    setState(() {
      _height = _sizeKey.currentContext!.size!.height;
      _createSizeAnimation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (c, w) {
        return SizedBox(
          height: _sizeAnimation.value,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: SwipeDetector(
              onSwipe: (SwipeDirection direction) {
                if (direction == SwipeDirection.rightToLeft) {
                  _complete();
                }
              },
              velocityThreshhold: 150,
              acceptedSwipes: AcceptedSwipes.horizontal,
              child: Container(
                key: _sizeKey,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: widget.paddingTop,
                    bottom: widget.paddingBottom,
                    left: widget.paddingLeft,
                    right: widget.paddingRight,
                  ),
                  child: Transform.translate(
                    offset: Offset(_appearAnimation.value, 0.0),
                    child: Material(
                      borderRadius: adaptiveRadius(100.0),
                      elevation: 50.0,
                      child: ClipRRect(
                        borderRadius: adaptiveRadius(100.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: _width,
                              constraints: const BoxConstraints(
                                minHeight: kBigButtonHeight,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                  kPadding,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: kPadding,
                                              left: kPadding,
                                            ),
                                            child: _buildIcon(),
                                          ),
                                          Expanded(
                                            child: Stack(
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Header(
                                                      text: widget.data.title,
                                                      paddingBottom: 5.0,
                                                      textAlign: TextAlign.left,
                                                    ),
                                                    Description(
                                                      text: widget.data.text,
                                                      paddingBottom: 5.0,
                                                      textAlign: TextAlign.left,
                                                    ),
                                                  ],
                                                ),
                                                Positioned(
                                                  right: 0.0,
                                                  top: 0.0,
                                                  child: GestureDetector(
                                                    onTap: _complete,
                                                    child: Container(
                                                      color: Colors.transparent,
                                                      child: IgnorePointer(
                                                        child: Icon(
                                                          Icons.close,
                                                          color: CustomColorTheme.of(context).normalTextColor,
                                                          size: 18.0,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: _width,
                              child: LinearProgressIndicator(
                                value: widget.data._progress,
                                backgroundColor: _color.withOpacity(.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
