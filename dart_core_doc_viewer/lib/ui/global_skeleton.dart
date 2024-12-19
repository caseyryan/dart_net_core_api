import 'dart:async';
import 'dart:collection';

import 'package:dart_core_doc_viewer/constants.dart';
import 'package:flutter/material.dart';

class NonAnimatedSkeletonStub extends StatelessWidget {
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;
  final double? width;
  final double? height;

  final Color? color;
  final double borderRadius;
  final bool fromCard;

  const NonAnimatedSkeletonStub({
    super.key,
    required this.borderRadius,
    this.paddingTop = 0.0,
    this.paddingBottom = 0.0,
    this.paddingLeft = 0.0,
    this.paddingRight = 0.0,
    this.width,
    this.height,
    this.fromCard = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: paddingTop,
        bottom: paddingBottom,
        left: paddingLeft,
        right: paddingRight,
      ),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(borderRadius),
          ),
          color: color,
        ),
      ),
    );
  }
}

Widget buildSkeleton({
  required BuildContext context,
  required double width,
  required double height,
}) {
  return GlobalSkeleton(
    paddingLeft: 0.0,
    paddingRight: 0.0,
    height: height,
    width: width,
    isEnabled: true,
    color: Theme.of(context).cardColor,
    borderRadius: kBorderRadius,
  );
}

class GlobalSkeleton extends StatefulWidget {
  const GlobalSkeleton({
    super.key,
    this.color,
    this.child,
    this.aspectRatio,
    this.isEnabled = true,
    this.paddingTop = 0.0,
    this.paddingBottom = 0.0,
    this.paddingLeft = 0.0,
    this.paddingRight = 0.0,
    this.width,
    this.begin = 0.2,
    this.end = 1.0,
    this.borderRadius,
    this.height,
    this.curve = Curves.linear,
    this.fromCard = false,
    this.isSliver = false,
  })  : assert(
          end > begin && (begin >= 0.0 && begin < 1.0) && (end <= 1.0 && end > 0.0),
        );

  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;
  final double? width;
  final double? height;
  final double? borderRadius;
  final Color? color;
  final Widget? child;
  final bool isSliver;
  final bool fromCard;
  final double begin;
  final double end;
  final Curve curve;
  final bool isEnabled;
  final double? aspectRatio;

  @override
  State<GlobalSkeleton> createState() => _GlobalSkeletonState();
}

class _GlobalSkeletonState extends State<GlobalSkeleton> {
  static const int kTick = 16;
  static int _millis = 0;
  static int _multiplier = 1;
  static const int _durationMillis = 600;
  final ValueNotifier<double> _listenable = ValueNotifier(0.0);
  static final HashSet<ValueNotifier<double>> _allListenable = HashSet<ValueNotifier<double>>();

  static bool _isDisposingSomething = false;

  static Timer? _timer;

  @override
  void initState() {
    _allListenable.add(_listenable);
    _createAnimationController();
    super.initState();
  }

  void _createAnimationController() {
    _timer ??= Timer.periodic(
      const Duration(
        milliseconds: kTick,
      ),
      _onTimer,
    );
  }

  static void _onTimer(timer) {
    _millis += kTick * _multiplier;
    if (_millis >= _durationMillis || _millis <= 0) {
      _multiplier *= -1;
    }
    _millis = _millis.clamp(0, _durationMillis);
    if (!_isDisposingSomething) {
      for (var l in _allListenable) {
        l.value = _millis / _durationMillis;
      }
    }
  }

  @override
  void dispose() {
    _isDisposingSomething = true;
    _allListenable.remove(_listenable);
    if (_allListenable.isEmpty) {
      _timer?.cancel();
      _timer = null;
    }
    _isDisposingSomething = false;
    super.dispose();
  }

  double get _value {
    return Interval(
      0.0,
      1.0,
      curve: widget.curve,
    )
        .transform(
          _listenable.value,
        )
        .clamp(
          widget.begin,
          widget.end,
        );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled && widget.child != null) {
      return widget.child!;
    }
    Widget child = ValueListenableBuilder(
      key: ValueKey(_listenable),
      valueListenable: _listenable,
      builder: (context, value, child) {
        Widget innerChild = Opacity(
          opacity: _value,
          child: Container(
            key: ValueKey(_listenable),
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: widget.borderRadius != null
                  ? BorderRadius.all(
                      Radius.circular(
                        widget.borderRadius!,
                      ),
                    )
                  : null,
            ),
            child: widget.child,
          ),
        );

        if (widget.aspectRatio != null) {
          innerChild = AspectRatio(
            aspectRatio: widget.aspectRatio!,
            child: innerChild,
          );
        }
        return Padding(
          padding: EdgeInsets.only(
            top: widget.paddingTop,
            bottom: widget.paddingBottom,
            left: widget.paddingLeft,
            right: widget.paddingRight,
          ),
          child: innerChild,
        );
      },
    );

    if (widget.isSliver) {
      return SliverToBoxAdapter(
        child: child,
      );
    }
    return child;
  }
}
