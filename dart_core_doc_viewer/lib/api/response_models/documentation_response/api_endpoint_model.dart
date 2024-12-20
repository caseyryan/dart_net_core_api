// ignore_for_file: depend_on_referenced_packages
import 'package:json_annotation/json_annotation.dart';
import 'endpoint_param.dart';
import 'response_model.dart';

part 'api_endpoint_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ApiEndpointModel {
  ApiEndpointModel({
    this.description,
    this.title,
    this.method,
    this.path,
    this.responseModels,
    this.params,
  });

  String? description;
  String? title;
  String? method;
  String? path;
  @JsonKey(name: 'response_models')
  List<ResponseModel>? responseModels;
  List<EndpointParam>? params;

  String? _searchString;

  @JsonKey(includeFromJson: false, includeToJson: false)
  String get searchString {
    if (_searchString?.isNotEmpty != true) {
      final responseSearchStrings = responseModels?.map((e) => e.searchString).join('');
      _searchString = '$responseSearchStrings,$path,$method$title$description'.toLowerCase();
    }
    return _searchString ?? '';
  }

  bool isMatchingSearch(String searchFor) {
    return searchString.contains(searchFor.toLowerCase());
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool isExpanded = false;

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
