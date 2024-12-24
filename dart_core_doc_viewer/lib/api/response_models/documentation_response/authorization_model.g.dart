// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authorization_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthorizationModel _$AuthorizationModelFromJson(Map<String, dynamic> json) =>
    AuthorizationModel(
      requiredHeaders: (json['required_headers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      roles:
          (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$AuthorizationModelToJson(AuthorizationModel instance) =>
    <String, dynamic>{
      'required_headers': instance.requiredHeaders,
      'roles': instance.roles,
    };
