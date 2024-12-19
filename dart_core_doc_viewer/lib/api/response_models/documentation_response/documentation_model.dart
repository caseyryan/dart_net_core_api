// ignore_for_file: depend_on_referenced_packages
import 'package:json_annotation/json_annotation.dart';
import 'controller_api_model.dart';

part 'documentation_model.g.dart';

@JsonSerializable(explicitToJson: true)
class DocumentationModel {
  DocumentationModel({
    this.controllers,
  });

  List<ControllerApiModel>? controllers;

  static DocumentationModel deserialize(Map<String, dynamic> json) {
    return DocumentationModel.fromJson(json);
  }

  factory DocumentationModel.fromJson(Map<String, dynamic> json) {
      return _$DocumentationModelFromJson(json);
    }
  
  Map<String, dynamic> toJson() {
    return _$DocumentationModelToJson(this);
  }
}
