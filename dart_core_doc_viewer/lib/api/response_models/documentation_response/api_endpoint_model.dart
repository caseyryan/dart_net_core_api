// ignore_for_file: depend_on_referenced_packages
import 'package:json_annotation/json_annotation.dart';
import 'response_model.dart';

part 'api_endpoint_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ApiEndpointModel {
  ApiEndpointModel({
    this.description,
    this.method,
    this.path,
    this.responseModels,
  });

  String? description;
  String? method;
  String? path;
  @JsonKey(name: 'response_models')
  List<ResponseModel>? responseModels;

  static ApiEndpointModel deserialize(Map<String, dynamic> json) {
    return ApiEndpointModel.fromJson(json);
  }

  factory ApiEndpointModel.fromJson(Map<String, dynamic> json) {
      return _$ApiEndpointModelFromJson(json);
    }
  
  Map<String, dynamic> toJson() {
    return _$ApiEndpointModelToJson(this);
  }
}
