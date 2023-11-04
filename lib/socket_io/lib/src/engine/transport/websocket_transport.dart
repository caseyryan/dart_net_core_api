// ignore_for_file: implementation_imports, avoid_renaming_method_parameters

import 'dart:async';

import 'package:dart_net_core_api/socket_io/lib/src/engine/transport/transports.dart';
/// websocket_transport.dart
///
/// Purpose:
///
/// Description:
///
/// History:
///    22/02/2017, Created by jumperchen
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
import 'package:logging/logging.dart';
import 'package:socket_io_common/src/engine/parser/parser.dart';

class WebSocketTransport extends Transport {
  static final Logger _logger =
      Logger('socket_io:transport.WebSocketTransport');
  @override
  bool get handlesUpgrades => true;
  @override
  bool get supportsFraming => true;
  StreamSubscription? subscription;
  WebSocketTransport(connect) : super(connect) {
    name = 'websocket';
    this.connect = connect;
    subscription =
        connect.websocket.listen(onData, onError: onError, onDone: onClose);
    writable = true;
  }

  @override
  void send(List<Map> data) {
    send(data, Map packet) {
      _logger.fine('writing "$data"');
      connect!.websocket?.add(data);
    }
    
    for (var i = 0; i < data.length; i++) {
      var packet = data[i];
      PacketParser.encodePacket(packet,
          supportsBinary: supportsBinary, callback: (_) => send(_, packet));
    }
  }

  @override
  void onClose() {
    super.onClose();

    // workaround for https://github.com/dart-lang/sdk/issues/27414
    if (subscription != null) {
      subscription!.cancel();
      subscription = null;
    }
  }

  @override
  void doClose([fn]) {
    connect!.websocket?.close();
    if (fn != null) fn();
  }
}
