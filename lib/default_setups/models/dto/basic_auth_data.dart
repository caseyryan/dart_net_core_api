import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

class BasicSignupData {
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
  @PasswordValidator()
  late String password;

  @JsonTrimString()
  @NameValidator(canBeNull: true)
  String? firstName;

  @JsonTrimString()
  @NameValidator(canBeNull: true)
  String? lastName;

  @JsonTrimString()
  @NameValidator(canBeNull: true)
  String? middleName;

  @JsonTrimString()
  @NameValidator(canBeNull: true)
  String? nickName;

  @JsonDateConverter(
    dateFormat: 'yyyy-MM-dd',
  )
  DateTime? birthDate;

  void validate() {
    if (email?.isNotEmpty != true && phone?.isNotEmpty != true) {
      throw ApiException(
        message: 'You must provide either email of a phone number',
      );
    }
  }
}
