import 'dart:math';

import 'package:dart_core_doc_viewer/utils/navigator_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


enum ScreenType {
  mobile,
  tablet,
  desktop,
}

ScreenType get screenType {
  if (screenWidth > 900.0 && screenWidth < 1600) {
    return ScreenType.tablet;
  }
  if (screenWidth >= 1600.0) {
    return ScreenType.desktop;
  }
  return ScreenType.mobile;
}

bool get isMobile {
  return screenType == ScreenType.mobile;
}

bool get isTablet {
  return screenType == ScreenType.tablet;
}

bool get isDesktop {
  return screenType == ScreenType.desktop;
}

double get topInset {
  return max(MediaQuery.of(appContext).viewPadding.top, .0000001);
}

double get bottomInset {
  return MediaQuery.of(appContext).viewPadding.bottom;
}

double get halfHeight {
  return screenHeightScaled / 2.0;
}

double get halfWidthScaled {
  return screenWidthScaled / 2.0;
}

double get screenWidth {
  return MediaQuery.of(appContext).size.width;
}

double get screenWidthScaled {
  return MediaQuery.of(appContext).size.width;
}

double get screenHeight {
  return MediaQuery.of(appContext).size.height;
}

double get screenAspectRatio {
  final aspectRatio = screenWidthScaled / screenHeightScaled;
  return aspectRatio;
}

bool get isNarrowScreen {
  return screenWidthScaled < screenHeightScaled;
}

double get screenHeightScaled {
  return MediaQuery.of(appContext).size.height;
}
