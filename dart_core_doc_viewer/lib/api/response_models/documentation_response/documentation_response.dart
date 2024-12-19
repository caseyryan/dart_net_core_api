// ignore_for_file: depend_on_referenced_packages
import 'package:json_annotation/json_annotation.dart';

import 'documentation_model.dart';

part 'documentation_response.g.dart';


@JsonSerializable(explicitToJson: true)
class DocumentationResponse {
  DocumentationResponse({
    this.data,
  });

  DocumentationModel? data;

  static DocumentationModel deserialize(Map<String, dynamic> json) {
    return DocumentationModel.fromJson(json);
  }

  factory DocumentationResponse.fromJson(Map<String, dynamic> json) {
      return _$DocumentationResponseFromJson(json);
    }
  
  Map<String, dynamic> toJson() {
    return _$DocumentationResponseToJson(this);
  }
}
