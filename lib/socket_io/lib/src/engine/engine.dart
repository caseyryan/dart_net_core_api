/// engine.dart
///
/// Purpose:
///
/// Description:
///
/// History:
///    16/02/2017, Created by jumperchen
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
import 'package:dart_net_core_api/socket_io/lib/src/engine/server.dart';
import 'package:dart_net_core_api/socket_io/lib/src/util/event_emitter.dart';

class Engine extends EventEmitter {
  static Engine attach(server, [Map? options]) {
    var engine = Server(options);
    engine.attachTo(server, options);
    return engine;
  }

  dynamic operator [](Object key) {}

  /// Associates the [key] with the given [value].
  ///
  /// If the key was already in the map, its associated value is changed.
  /// Otherwise the key-value pair is added to the map.
  void operator []=(String key, dynamic value) {}
//  init() {}
//  upgrades() {}
//  verify() {}
//  prepare() {}
  void close() {}
//  handleRequest() {}
//  handshake() {}
}
