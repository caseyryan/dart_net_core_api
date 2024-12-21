// ignore_for_file: depend_on_referenced_packages
import 'package:json_annotation/json_annotation.dart';


part 'endpoint_param.g.dart';

@JsonSerializable(explicitToJson: true)
class EndpointParam {
  EndpointParam({
    this.type,
    this.name,
    this.isBodyParam,
    this.isRequired,
  });

  Object? type;
  String? name;
  @JsonKey(name: 'is_body_param')
  bool? isBodyParam;
  @JsonKey(name: 'is_required')
  bool? isRequired;

  static EndpointParam deserialize(Map<String, dynamic> json) {
    return EndpointParam.fromJson(json);
  }

  factory EndpointParam.fromJson(Map<String, dynamic> json) {
      return _$EndpointParamFromJson(json);
    }
  
  Map<String, dynamic> toJson() {
    return _$EndpointParamToJson(this);
  }
}
