// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'endpoint_param.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EndpointParam _$EndpointParamFromJson(Map<String, dynamic> json) =>
    EndpointParam(
      type: json['type'],
      name: json['name'] as String?,
      isBodyParam: json['is_body_param'] as bool?,
      isRequired: json['is_required'] as bool?,
    );

Map<String, dynamic> _$EndpointParamToJson(EndpointParam instance) =>
    <String, dynamic>{
      'type': instance.type,
      'name': instance.name,
      'is_body_param': instance.isBodyParam,
      'is_required': instance.isRequired,
    };
