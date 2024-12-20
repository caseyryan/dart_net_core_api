// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ResponseModel {
  ResponseModel({
    this.statusCode,
    this.contentType,
    this.response,
  });

  @JsonKey(name: 'status_code')
  int? statusCode;
  @JsonKey(name: 'content_type')
  String? contentType;
  Map? response;

  String? _searchString;
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get searchString {
    if (_searchString?.isNotEmpty != true) {
      _searchString = '${jsonEncode(response)},$statusCode';
    }
    return _searchString ?? '';
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get isSuccess => statusCode! >= 200 && statusCode! < 300;

  static ResponseModel deserialize(Map<String, dynamic> json) {
    return ResponseModel.fromJson(json);
  }

  factory ResponseModel.fromJson(Map<String, dynamic> json) {
      return _$ResponseModelFromJson(json);
    }
  
  Map<String, dynamic> toJson() {
    return _$ResponseModelToJson(this);
  }
}
