// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'documentation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentationModel _$DocumentationModelFromJson(Map<String, dynamic> json) =>
    DocumentationModel(
      controllers: (json['controllers'] as List<dynamic>?)
          ?.map((e) => ControllerApiModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      types:
          (json['types'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$DocumentationModelToJson(DocumentationModel instance) =>
    <String, dynamic>{
      'controllers': instance.controllers?.map((e) => e.toJson()).toList(),
      'types': instance.types,
    };
