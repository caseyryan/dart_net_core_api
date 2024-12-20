import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kNormalFontSize = 16.0;

double get bigTextSize => 32.0 * customFontScale;
double get normalTextSize => kNormalFontSize * customFontScale;
double get tinyTextSize => 13.0 * customFontScale;
/// Используется для иероглифов в упражнениях
double get mediumTextSize => 22.0 * customFontScale;

double get customFontScale {
  return 1.0;
}


@immutable
class CustomTextTheme extends ThemeExtension<CustomTextTheme> {
  const CustomTextTheme({
    required this.mainWordStyle,
    required this.transcriptionStyle,
    required this.defaultStyle,
    required this.exerciseTextStyle,
    required this.captionStyle,
    required this.descriptionStyle,
    required this.headerStyle,
    this.marginStyle,
    this.italicStyle,
    this.exampleStyle,
    this.boldStyle,
    this.labelStyle,
    this.refStyle,
    this.starStyle,
    this.coloredStyle,
  });

  /// i - italic
  /// c - colored (highlighted) type.
  /// mN -  - this tag sets the left paragraph margin
  /// ex - to mark a sample section.
  /// b - bold
  /// p - labels marking (when a label is pressed a window with its definition appears).
  /// ref - - reference to a card in the same dictionary (you may also use << and >>
  /// signs to enclose the card heading to make a reference).
  /// (counted from the left card margin). N is any digit from 0 to 9. N spaces
  /// * the text between these tags is only displayed in full
  /// translation mode (see); sample translations etc.
  /// are usually marked by these tags

  final TextStyle exerciseTextStyle;
  
  final TextStyle descriptionStyle;
  final TextStyle captionStyle;
  final TextStyle headerStyle;

  final TextStyle mainWordStyle;
  final TextStyle transcriptionStyle;
  final TextStyle defaultStyle; // mN
  final TextStyle? marginStyle; // mN
  final TextStyle? italicStyle; // i
  final TextStyle? exampleStyle; // ex
  final TextStyle? boldStyle; // b
  final TextStyle? labelStyle; // p
  final TextStyle? refStyle; // ref
  final TextStyle? starStyle; // *
  final TextStyle? coloredStyle; // c

  factory CustomTextTheme.dark() {
    return CustomTextTheme(
      mainWordStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontSize: bigTextSize,
        fontWeight: FontWeight.w600,
      ),
      transcriptionStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontSize: normalTextSize,
      ),
      captionStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontSize: tinyTextSize,
        color: const Color.fromARGB(255, 132, 132, 132),
      ),
      descriptionStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontSize: normalTextSize,
      ),
      headerStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontSize: mediumTextSize,
        fontWeight: FontWeight.w500,
      ),
      exerciseTextStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontSize: mediumTextSize,
      ),
      defaultStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontSize: normalTextSize,
      ),
      marginStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontSize: normalTextSize,
      ),
      exampleStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontSize: normalTextSize,
      ),
      starStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        color: const Color.fromARGB(255, 204, 214, 255),
        fontSize: normalTextSize,
      ),
      italicStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontStyle: FontStyle.italic,
        fontSize: normalTextSize,
      ),
      labelStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        // fontStyle: FontStyle.italic,
        color: Colors.grey,
        fontSize: normalTextSize,
      ),
      refStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontStyle: FontStyle.italic,
        color: Colors.grey,
        fontSize: normalTextSize,
      ),
      boldStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontWeight: FontWeight.bold,
        fontSize: normalTextSize,
      ),
      coloredStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        color: const Color.fromARGB(255, 255, 132, 123),
        fontSize: normalTextSize,
      ),
    );
  }

  factory CustomTextTheme.light() {
    return CustomTextTheme(
      mainWordStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontSize: bigTextSize,
        fontWeight: FontWeight.w600,
      ),
      captionStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontSize: tinyTextSize,
        color: const Color.fromARGB(255, 67, 64, 64),
      ),
      descriptionStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontSize: normalTextSize,
      ),
      headerStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontSize: mediumTextSize,
        fontWeight: FontWeight.w500,
      ),
      exerciseTextStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontSize: mediumTextSize,
      ),
      transcriptionStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontSize: normalTextSize,
      ),
      defaultStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontSize: normalTextSize,
      ),
      marginStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontSize: normalTextSize,
      ),
      exampleStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontSize: normalTextSize,
      ),
      starStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        color: Colors.deepPurple,
      ),
      italicStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontStyle: FontStyle.italic,
        fontSize: normalTextSize,
      ),
      labelStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        // fontStyle: FontStyle.italic,
        color: Colors.grey,
        fontSize: normalTextSize,
      ),
      refStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontStyle: FontStyle.italic,
        color: Colors.grey,
        fontSize: normalTextSize,
      ),
      boldStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        fontWeight: FontWeight.bold,
        fontSize: normalTextSize,
      ),
      coloredStyle: GoogleFonts.lato().copyWith(
        inherit: true,
        color: Colors.red,
        fontSize: normalTextSize,
      ),
    );
  }

  TextStyle getTextStyleForTag(String tagName) {
    if (tagName == 'i') {
      return italicStyle ?? defaultStyle;
    } else if (tagName == 'c') {
      return coloredStyle ?? defaultStyle;
    } else if (tagName == 'm') {
      return marginStyle ?? defaultStyle;
    } else if (tagName == 'ex') {
      return exampleStyle ?? defaultStyle;
    } else if (tagName == 'b') {
      return boldStyle ?? defaultStyle;
    } else if (tagName == 'p') {
      return labelStyle ?? defaultStyle;
    } else if (tagName == 'ref') {
      return refStyle ?? defaultStyle;
    } else if (tagName == '*') {
      return starStyle ?? defaultStyle;
    }
    return defaultStyle;
  }

  @override
  ThemeExtension<CustomTextTheme> copyWith() {
    return this;
  }

  @override
  ThemeExtension<CustomTextTheme> lerp(
    covariant ThemeExtension<CustomTextTheme>? other,
    double t,
  ) {
    return this;
  }

  static CustomTextTheme of(BuildContext context) {
    return Theme.of(context).extension<CustomTextTheme>()!;
  }
}
