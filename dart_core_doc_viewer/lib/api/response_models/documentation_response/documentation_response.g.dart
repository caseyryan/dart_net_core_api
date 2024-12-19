// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'documentation_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentationResponse _$DocumentationResponseFromJson(
        Map<String, dynamic> json) =>
    DocumentationResponse(
      data: json['data'] == null
          ? null
          : DocumentationModel.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DocumentationResponseToJson(
        DocumentationResponse instance) =>
    <String, dynamic>{
      'data': instance.data?.toJson(),
    };
