// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResponseModel _$ResponseModelFromJson(Map<String, dynamic> json) =>
    ResponseModel(
      statusCode: (json['status_code'] as num?)?.toInt(),
      contentType: json['content_type'] as String?,
      response: json['response'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ResponseModelToJson(ResponseModel instance) =>
    <String, dynamic>{
      'status_code': instance.statusCode,
      'content_type': instance.contentType,
      'response': instance.response,
    };
