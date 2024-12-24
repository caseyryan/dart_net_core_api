// ignore_for_file: depend_on_referenced_packages
import 'package:json_annotation/json_annotation.dart';

part 'authorization_model.g.dart';

@JsonSerializable(explicitToJson: true)
class AuthorizationModel {
  AuthorizationModel({
    this.requiredHeaders,
    this.roles,
  });

  @JsonKey(name: 'required_headers')
  List<String>? requiredHeaders;
  List<String>? roles;

  static AuthorizationModel deserialize(Map<String, dynamic> json) {
    return AuthorizationModel.fromJson(json);
  }

  factory AuthorizationModel.fromJson(Map<String, dynamic> json) {
      return _$AuthorizationModelFromJson(json);
    }
  
  Map<String, dynamic> toJson() {
    return _$AuthorizationModelToJson(this);
  }
}
