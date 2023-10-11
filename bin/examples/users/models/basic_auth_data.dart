import 'package:dart_net_core_api/jwt/annotations/validating_annotations.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

class BasicAuthData {

  @EmailValidator(canBeNull: false)
  late String email;
  @JsonPasswordValidator()
  late String password;
}