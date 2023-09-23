import 'package:dart_net_core_api/annotations/controller_annotations.dart';
import 'package:dart_net_core_api/controllers/api_controller.dart';
import 'package:dart_net_core_api/server.dart';

void main(List<String> arguments) {
  // ControllerTypeReflection(TestController2);
  // final controllerReflection = ControllerTypeReflector(
  //   TestController,
  // );
  // final instance = controllerReflection.instantiateController(
  //   services: ,
  // );

  // final mapper = controllerReflection.tryFindEndpointMapper(
  //   path: '/api/v1/user/123?firstName=stood',
  //   method: 'GET',
  // );
  // print(mapper?.fullPath);

  // print(type.hasEndpoints);
  // print(type.toMap().toFormattedJson());

  // final endpoints = <String>[
  //   '/user/{:id}',
  //   '/user/{id}/dome',
  // ];
  // final parsers = <EndpointPathParser>[];

  // for (var e in endpoints) {
  //   parsers.add(EndpointPathParser(e));
  // }
  // // for (var p in parsers) {
  // //   p.printPathWithParams();
  // // }

  // final testPoints = [
  //   'https://example.com/user/123/dome?name=stood',
  //   // '/user/123/dome',
  // ];
  // final incomingParsers = <IncomingPathParser>[];
  // for (var t in testPoints) {
  //   incomingParsers.add(IncomingPathParser(t));
  // }

  // for (var incomingParser in incomingParsers) {
  //   for (var p in parsers) {
  //     if (p.tryMatchPath(incomingParser)) {
  //       print(incomingParser.toMap().toFormattedJson());
  //       // p.printPathWithParams();
  //     }
  //   }
  // }

  // return;
  final server = Server(
    apiControllers: [
      TestController,
    ],
    singletonServices: [
      Service1(),
    ],
  );
  // server.addSingletonService(Service1());

  // print('GOOD');
}

@BaseApiPath('/api/v1')
class TestController extends ApiController {
  Service1 service;
  double? numericValue;

  TestController(
    this.service,
  );

  @HttpGet('/user/{:id}')
  String getUser(int id) {
    return 'Vasya';
  }
}

class Service1 extends Service {}

class Service2 extends Service {}
