// ignore_for_file: depend_on_referenced_packages
import 'package:json_annotation/json_annotation.dart';


part 'api_group_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ApiGroupModel {
  ApiGroupModel({
    this.name,
    this.id,
  });

  String? name;
  String? id;

  static ApiGroupModel deserialize(Map<String, dynamic> json) {
    return ApiGroupModel.fromJson(json);
  }

  factory ApiGroupModel.fromJson(Map<String, dynamic> json) {
      return _$ApiGroupModelFromJson(json);
    }
  
  Map<String, dynamic> toJson() {
    return _$ApiGroupModelToJson(this);
  }
}
