import 'dart:math';

import 'package:dart_core_doc_viewer/constants.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

BorderRadius adaptiveRadius([
  double? elementHeight,
]) {
  return SmoothBorderRadius.all(
    SmoothRadius(
      cornerRadius: elementHeight != null
          ? min(
              kBorderRadius,
              elementHeight * .20,
            )
          : kBorderRadius,
      cornerSmoothing: 1.0,
    ),
  );
}
