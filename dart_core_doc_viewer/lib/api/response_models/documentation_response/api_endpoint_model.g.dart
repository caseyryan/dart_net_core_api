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
    );

Map<String, dynamic> _$ApiEndpointModelToJson(ApiEndpointModel instance) =>
    <String, dynamic>{
      'description': instance.description,
      'title': instance.title,
      'method': instance.method,
      'path': instance.path,
      'response_models':
          instance.responseModels?.map((e) => e.toJson()).toList(),
    };
