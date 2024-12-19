import 'package:flutter/material.dart';

import 'theme_extensions/custom_color_theme.dart';
import 'theme_extensions/custom_text_theme.dart';

class LightTheme {
  static const ColorScheme colorScheme = ColorScheme.light();
  static const TextStyle textStyle = TextStyle(
    color: Colors.black,
  );
  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: const TextTheme(
      bodyMedium: textStyle,
    ),
    extensions: [
      CustomColorTheme.light(),
      CustomTextTheme.light(),
    ],
  );
}

class DarkTheme {
  static const ColorScheme colorScheme = ColorScheme.dark();
  static const TextStyle textStyle = TextStyle(
    color: Colors.white,
  );
  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: const TextTheme(
      bodyMedium: textStyle,
    ),
    extensions: [
      CustomColorTheme.dark(),
      CustomTextTheme.dark(),
    ],
  );
}
