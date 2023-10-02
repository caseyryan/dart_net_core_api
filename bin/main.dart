import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/utils/mirror_utils/simple_type_reflector.dart';

import 'test_controller.dart';

/// https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/
void main(List<String> arguments) {
  // final mirror = JsonTypeReflector(ToSerialize);
  final instance = (ToSerialize).fromJson({
    '_id': '123123',
    'age': 9,
    'first_name': 'Steve',
    'values': ['John', 'Jay'],
    'data': {
      'name': 'Mary',
    },
    'datas': [
      {
        'name': 'InnerName1',
      },
      {
        'name': 'InnerName2',
      },
    ],
    'fromMap': {
      'firstKey': [
        {'name': 'FirstJohn'},
      ]
    }
  });

  print(instance);

  return;
  Server(
    apiControllers: [
      TestController,
    ],
    singletonServices: [
      Service1(),
    ],
  );
}

class ToSerialize {
  // List<String>? values;
  // @JsonName('first_name')

  // @JsonStringValidator(
  //   canBeNull: false,
  //   regExpPattern: r'[a-zA-Z]+',
  // )
  // @JsonName('first_name')
  // String? firstName;
  // // double? price;

  // @JsonIntConverter(
  //   minValue: 10,
  //   maxValue: 32,
  //   canBeNull: false,
  // )
  // @JsonIntValidator(
  //   minValue: 10,
  //   maxValue: 32,
  //   canBeNull: false,
  // )
  // int? age;
  // @JsonInclude()
  // String? _id;

  Map<String, List<ToSerialize2>>? fromMap;

  // bool get isPrivate => false;
  // List<ToSerialize2>? datas;
  // ToSerialize2? data;
}

class ToSerialize2 {
  String? name;
}

class Service1 extends IService {}

class Service2 extends IService {}
