import 'package:dart_net_core_api/annotations/json_annotations.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/utils/json_utils/json_serializer.dart';

import 'controllers/user_controller.dart';
import 'services/user_service.dart';


void main(List<String> arguments) {
  Server(
    apiControllers: [
      UserController,
    ],
    singletonServices: [
      UserService(),
    ],
    jsonSerializer: DefaultJsonSerializer(
      CamelToSnakeConverter(),
    ),
    baseApiPath: '/api/v1'
  );
}

class ToSerialize {
  List<String>? values;

  @JsonStringValidator(
    canBeNull: false,
    regExpPattern: r'[a-zA-Z]+',
  )
  @JsonName('first_name')
  String? firstName;
  // double? price;

  @JsonIntConverter(
    minValue: 10,
    maxValue: 32,
    canBeNull: false,
  )
  @JsonIntValidator(
    minValue: 10,
    maxValue: 32,
    canBeNull: false,
  )
  int? age;
  // @JsonInclude()
  String? _id;

  // Map<String, ToSerialize2>? fromMap;
  ToSerialize2? fromStringMap;
  // List<String>? fromStringList;

  // bool get isPrivate => false;
  List<ToSerialize2>? datas;
  // ToSerialize2? data;
}

class ToSerialize2 {
  String? name;
}

class Service1 extends IService {}

class Service2 extends IService {}
