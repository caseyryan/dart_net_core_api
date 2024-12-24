// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_endpoint_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiEndpointModel _$ApiEndpointModelFromJson(Map<String, dynamic> json) =>
    ApiEndpointModel(
      description: json['description'] as String?,
      title: json['title'] as String?,
      method: json['method'] as String?,
      path: json['path'] as String?,
      responseModels: (json['response_models'] as List<dynamic>?)
          ?.map((e) => ResponseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      params: (json['params'] as List<dynamic>?)
          ?.map((e) => EndpointParam.fromJson(e as Map<String, dynamic>))
          .toList(),
      authorization: json['authorization'] == null
          ? null
          : AuthorizationModel.fromJson(
              json['authorization'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ApiEndpointModelToJson(ApiEndpointModel instance) =>
    <String, dynamic>{
      'description': instance.description,
      'title': instance.title,
      'method': instance.method,
      'authorization': instance.authorization?.toJson(),
      'path': instance.path,
      'response_models':
          instance.responseModels?.map((e) => e.toJson()).toList(),
      'params': instance.params?.map((e) => e.toJson()).toList(),
    };
