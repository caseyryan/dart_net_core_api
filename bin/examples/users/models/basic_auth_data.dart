import 'package:reflect_buddy/reflect_buddy.dart';

class BasicAuthData {

  @EmailValidator(canBeNull: false)
  late String email;
  @JsonStringValidator(canBeNull: false)
  late String password;
}