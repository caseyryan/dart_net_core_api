import 'package:flutter/material.dart';

@immutable
class CustomColorTheme extends ThemeExtension<CustomColorTheme> {
  const CustomColorTheme({
    required this.circleButtonBackground,
    required this.circleButtonIconColor,
    required this.actionSheetColor,
    required this.paleBackgroundColor,
    required this.positiveColor,
    required this.negativeColor,
    required this.warningColor,
    required this.normalTextColor,
    required this.transparentButtonContentColor,
    required this.labelColor,
    required this.wordHighlightColor,
  });
  
  final Color circleButtonBackground;
  final Color labelColor;
  final Color circleButtonIconColor;
  final Color normalTextColor;
  final Color transparentButtonContentColor;
  final Color actionSheetColor;
  final Color paleBackgroundColor;
  final Color positiveColor;
  final Color negativeColor;
  final Color warningColor;
  final Color wordHighlightColor;

  factory CustomColorTheme.light() {
    return const CustomColorTheme(
      circleButtonBackground: Colors.deepOrange,
      circleButtonIconColor: Colors.white,
      actionSheetColor: Colors.white,
      wordHighlightColor: Color.fromARGB(255, 250, 250, 224),
      paleBackgroundColor: Color.fromARGB(255, 247, 247, 247),
      positiveColor: Color.fromARGB(255, 32, 187, 37),
      negativeColor: Color.fromARGB(255, 238, 131, 131),
      warningColor: Colors.orange,
      transparentButtonContentColor: Color(0xFF373737),
      normalTextColor: Color(0xFF373737),
      labelColor: Color.fromARGB(255, 239, 239, 239),
    );
  }
  factory CustomColorTheme.dark() {
    return const CustomColorTheme(
      circleButtonBackground: Color.fromARGB(255, 82, 82, 82),
      circleButtonIconColor: Color.fromARGB(255, 233, 233, 233),
      actionSheetColor: Color.fromARGB(255, 41, 41, 41),
      paleBackgroundColor: Color.fromARGB(255, 55, 55, 55),
      positiveColor: Color.fromARGB(255, 62, 157, 65),
      negativeColor: Color.fromARGB(255, 255, 72, 72),
      warningColor: Color.fromARGB(255, 255, 179, 72),
      wordHighlightColor: Color.fromARGB(255, 81, 81, 81),
      transparentButtonContentColor: Color.fromARGB(255, 243, 243, 243),
      normalTextColor: Color.fromARGB(255, 243, 243, 243),
      labelColor: Color.fromARGB(255, 87, 87, 87),
    );
  }


  @override
  CustomColorTheme copyWith() {
    return this;
  }

  @override
  CustomColorTheme lerp(
    ThemeExtension<CustomColorTheme>? other,
    double t,
  ) {
    if (other is! CustomColorTheme) {
      return this;
    }

    return CustomColorTheme(
      circleButtonBackground: Color.lerp(
        circleButtonBackground,
        other.circleButtonBackground,
        t,
      )!,
      circleButtonIconColor: Color.lerp(
        circleButtonIconColor,
        other.circleButtonIconColor,
        t,
      )!,
      actionSheetColor: Color.lerp(
        actionSheetColor,
        other.actionSheetColor,
        t,
      )!,
      positiveColor: Color.lerp(
        positiveColor,
        other.positiveColor,
        t,
      )!,
      negativeColor: Color.lerp(
        negativeColor,
        other.negativeColor,
        t,
      )!,
      warningColor: Color.lerp(
        warningColor,
        other.warningColor,
        t,
      )!,
      transparentButtonContentColor: Color.lerp(
        transparentButtonContentColor,
        other.transparentButtonContentColor,
        t,
      )!,
      normalTextColor: Color.lerp(
        normalTextColor,
        other.normalTextColor,
        t,
      )!,
      labelColor: Color.lerp(
        labelColor,
        other.labelColor,
        t,
      )!,
      paleBackgroundColor: Color.lerp(
        paleBackgroundColor,
        other.paleBackgroundColor,
        t,
      )!,
      wordHighlightColor: Color.lerp(
        wordHighlightColor,
        other.wordHighlightColor,
        t,
      )!,
    );
  }

  static CustomColorTheme of(BuildContext context) {
    return Theme.of(context).extension<CustomColorTheme>()!;
  }
}

List<Color> lerpColorList({
  required List<Color> from,
  required List<Color> to,
  required double t,
}) {
  assert(from.length == to.length);
  final temp = <Color>[];
  for (var i = 0; i < from.length; i++) {
    temp.add(Color.lerp(from[i], to[i], t)!);
  }
  return temp;
}
