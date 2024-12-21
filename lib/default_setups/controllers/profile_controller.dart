import 'dart:io';

import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/annotations/documentation_annotations/documentation_annotations.dart';
import 'package:dart_net_core_api/default_setups/models/db_models/abstract_user.dart';
import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

@APIControllerDocumentation(
  title: 'User Profile Controller',
  description: 'Works with the current user profile. It can return or update the user profile',
  group: ApiDocumentationGroup.userAreaGroup,
)
@BaseApiPath('/api/v1')
class ProfileController<TUser extends AbstractUser> extends ApiController {

  @APIEndpointDocumentation(
    responseModels: [
      APIResponseExample(
        statusCode: HttpStatus.ok,
        /// If you want to show your own user model 
        /// you must also provide [APIEndpointDocumentation] in the 
        /// overridden controller class. Generic types can not be used 
        /// in const constructors
        response: AbstractUser,
      ),
      APIResponseExample(
        statusCode: HttpStatus.unauthorized,
        /// If you want to show your own user model 
        /// you must also provide [APIEndpointDocumentation] in the 
        /// overridden controller class. Generic types can not be used 
        /// in const constructors
        response: UnAuthorizedException,
      ),
    ],
    title: 'Returns the current user\'s profile',
  )
  @HttpGet('/profile')
  Future<TUser> getUserProfile() async {
    return (TUser).newTypedInstance() as TUser;
  }
}
