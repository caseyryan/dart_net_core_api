import 'package:reflect_buddy/reflect_buddy.dart';

class JsonPasswordValidator extends JsonValueValidator {
  static final _digitsRegex = RegExp(r'[0-9]+');
  static final _upperCaseLettersRegex = RegExp(r'[A-ZА-ЯЁ]+');
  static final _lowerCaseLettersRegex = RegExp(r'[a-zа-яё]+');
  static final _specialCharRegex = RegExp("[\"!#\$%&')(*+,-\\.\\/:;<=>?@\\][^_`|}{~]+");

  const JsonPasswordValidator({
    this.minDigits = 1,
    this.minLength = 8,
    this.minLowerCaseLetters = 1,
    this.minSpecialChars = 1,
    this.minUpperCaseLetters = 1,
  }) : super(canBeNull: false);

  final int minLength;
  final int minSpecialChars;
  final int minUpperCaseLetters;
  final int minLowerCaseLetters;
  final int minDigits;


  bool _isDigitsOk(String value) {
    if (minDigits < 1) {
      return true;
    }
    return _digitsRegex.allMatches(value).length >= minDigits;
  }

  bool _isLengthOk(String value) {
    return value.length >= minLength;
  }

  bool _isLowerCaseOk(
    String value,
  ) {
    if (minLowerCaseLetters < 1) {
      return true;
    }
    return _lowerCaseLettersRegex.allMatches(value).length >= minLowerCaseLetters;
  }

  bool _isUpperCaseOk(
    String value,
  ) {
    if (minUpperCaseLetters < 1) {
      return true;
    }
    return _upperCaseLettersRegex.allMatches(value).length >= minUpperCaseLetters;
  }

  bool _isSpecialCharsOk(
    String value,
  ) {
    if (minSpecialChars < 1) {
      return true;
    }
    return _specialCharRegex.allMatches(value).length >= minSpecialChars;
  }

  String _getEnding(int num) {
    if (num < 2) {
      return '';
    }
    return 's';
  }

  @override
  void validate({
    covariant String? actualValue,
    required String fieldName,
  }) {
    if (checkForNull(
      canBeNull: canBeNull,
      fieldName: fieldName,
      actualValue: actualValue,
    )) {
      if (!_isDigitsOk(actualValue!)) {
        throw 'A password must contain at least $minDigits digit${_getEnding(minDigits)}';
      }
      if (!_isSpecialCharsOk(actualValue)) {
        throw 'A password must contain at least $minSpecialChars special character${_getEnding(minSpecialChars)}';
      }
      if (!_isLowerCaseOk(actualValue)) {
        throw 'A password must contain at least $minLowerCaseLetters lower case latin or cyrillic letter${_getEnding(minLowerCaseLetters)}';
      }
      if (!_isUpperCaseOk(actualValue)) {
        throw 'A password must contain at least $minUpperCaseLetters upper case latin or cyrillic letter${_getEnding(minUpperCaseLetters)}';
      }
      if (!_isLengthOk(actualValue)) {
        throw 'A password must be at least $minLength character${_getEnding(minLength)} long';
      }
    }
  }
}
