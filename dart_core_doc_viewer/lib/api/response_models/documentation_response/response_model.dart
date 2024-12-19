// ignore_for_file: depend_on_referenced_packages
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
