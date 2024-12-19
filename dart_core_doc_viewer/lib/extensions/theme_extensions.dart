import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_text_theme.dart';
import 'package:flutter/material.dart';



extension ThemeDataExtension on ThemeData {
  Color get secondaryColor {
    return colorScheme.secondary;
  }

  Color get cardBackgroundColor {
    return dialogBackgroundColor;
  }

  TextStyle get normalTextStyle {
    return extension<CustomTextTheme>()!.defaultStyle;
  }

  TextStyle get headerStyle {
    return extension<CustomTextTheme>()!.headerStyle;
  }

  TextStyle get smallTextStyle {
    return extension<CustomTextTheme>()!.captionStyle;
  }

  TextStyle get mediumTextStyle {
    return extension<CustomTextTheme>()!.descriptionStyle;
  }
}
