import 'package:dart_core_orm/dart_core_orm.dart';
import 'package:dart_net_core_api/default_setups/models/db_models/abstract_user.dart';
import 'package:dart_net_core_api/default_setups/models/dto/basic_auth_data.dart';
import 'package:dart_net_core_api/default_setups/models/dto/basic_login_data.dart';
import 'package:dart_net_core_api/exports.dart';
import 'package:dart_net_core_api/jwt/token_response.dart';

@TableName('users')
class CoolUser extends AbstractUser {}

/// This is an example of how you can override
/// the controller and provide your custom user model
/// instead of the base AbstractUser
class ExtendedAuthController extends AuthController<CoolUser, BasicSignupData, BasicLoginData> {
  ExtendedAuthController(
    super.jwtService,
    super.passwordHashService,
    super.failedPasswordBlockingService,
  );

  @override
  Future<TokenResponse?> login(
    @FromBody() BasicLoginData basicLoginData,
  ) async {
    print(basicLoginData);
    return super.login(basicLoginData);
  }

  @override
  Future<TokenResponse?> signup(
    @FromBody() BasicSignupData basicSignupData,
  ) async {
    print(basicSignupData);
    return super.signup(basicSignupData);
  }
}
