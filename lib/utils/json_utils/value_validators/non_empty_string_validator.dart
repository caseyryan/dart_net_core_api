import 'package:reflect_buddy/reflect_buddy.dart';

class NonEmptyStringValidator extends StringValidator {
  const NonEmptyStringValidator()
      : super(
          regExpPattern: r'^(?!\s*$).+',
          canBeNull: false,
        );
}
