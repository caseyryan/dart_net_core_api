// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controller_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ControllerApiModel _$ControllerApiModelFromJson(Map<String, dynamic> json) =>
    ControllerApiModel(
      controllerName: json['controller_name'] as String?,
      description: json['description'] as String?,
      title: json['title'] as String?,
      group: json['group'] == null
          ? null
          : ApiGroupModel.fromJson(json['group'] as Map<String, dynamic>),
      endpoints: (json['endpoints'] as List<dynamic>?)
          ?.map((e) => ApiEndpointModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      types:
          (json['types'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$ControllerApiModelToJson(ControllerApiModel instance) =>
    <String, dynamic>{
      'controller_name': instance.controllerName,
      'types': instance.types,
      'description': instance.description,
      'title': instance.title,
      'group': instance.group?.toJson(),
      'endpoints': instance.endpoints?.map((e) => e.toJson()).toList(),
    };
