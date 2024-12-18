import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
import 'package:dart_net_core_api/utils/json_utils/value_validators/non_empty_string_validator.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

class BasicLoginData {
  @JsonTrimString()
  @EmailValidator(canBeNull: true)
  String? email;

  @JsonTrimString()
  @PhoneValidator(canBeNull: true)
  @JsonPhoneConverter(
    addLeadingPlus: true,
    type: PhoneStringType.unformatted,
  )
  String? phone;
  
  @NonEmptyStringValidator()
  String? password;

  void validate() {
    if (email?.isNotEmpty != true && phone?.isNotEmpty != true) {
      throw ApiException(
        message: 'You must provide either email of a phone number',
      );
    }
  }
}
