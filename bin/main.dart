import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/utils/endpoint_path_parser.dart';
import 'package:dart_net_core_api/utils/extensions.dart';
import 'package:dart_net_core_api/utils/incoming_path_parser.dart';

import 'test_controller.dart';

void main(List<String> arguments) {
  final endpoints = <String>[
    '/user/{:id}',
    '/user/{id}/dome',
  ];
  final parsers = <EndpointPathParser>[];

  for (var e in endpoints) {
    parsers.add(EndpointPathParser(e));
  }
  // for (var p in parsers) {
  //   p.printPathWithParams();
  // }

  final testPoints = [
    'https://example.com/user/123/dome?name=stood',
    // '/user/123/dome',
  ];
  final incomingParsers = <IncomingPathParser>[];
  for (var t in testPoints) {
    incomingParsers.add(IncomingPathParser(t));
  }

  for (var incomingParser in incomingParsers) {
    for (var p in parsers) {
      if (p.tryMatchPath(incomingParser)) {
        print(incomingParser.toMap().toFormattedJson());
        // p.printPathWithParams();
      }
    }
  }

  return;
  Server(serviceTypes: [], apiControllers: [
    TestController,
  ]);
  print('GOOD');
}
