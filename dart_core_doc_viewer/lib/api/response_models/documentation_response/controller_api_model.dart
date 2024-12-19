// ignore_for_file: depend_on_referenced_packages
import 'package:json_annotation/json_annotation.dart';
import 'api_group_model.dart';
import 'api_endpoint_model.dart';

part 'controller_api_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ControllerApiModel {
  ControllerApiModel({
    this.controllerName,
    this.description,
    this.title,
    this.group,
    this.endpoints,
  });

  @JsonKey(name: 'controller_name')
  String? controllerName;
  String? description;
  String? title;
  ApiGroupModel? group;
  List<ApiEndpointModel>? endpoints;

  String getSafeTitle() {
    if (title?.isNotEmpty != true) {
      return controllerName!;
    }
    return title!;
  }

  static ControllerApiModel deserialize(Map<String, dynamic> json) {
    return ControllerApiModel.fromJson(json);
  }

  factory ControllerApiModel.fromJson(Map<String, dynamic> json) {
      return _$ControllerApiModelFromJson(json);
    }
  
  Map<String, dynamic> toJson() {
    return _$ControllerApiModelToJson(this);
  }
}
