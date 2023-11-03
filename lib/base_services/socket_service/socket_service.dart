// ignore_for_file: unused_element

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_net_core_api/annotations/socket_controller_annotations.dart';
import 'package:dart_net_core_api/base_services/socket_service/socket_controller.dart';
import 'package:dart_net_core_api/config.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/socket_io/lib/socket_io.dart' as socket_io;
import 'package:dart_net_core_api/socket_io/lib/src/namespace.dart';
import 'package:dart_net_core_api/socket_io/lib/src/util/event_emitter.dart';
import 'package:dart_net_core_api/utils/extensions.dart';
import 'package:dart_net_core_api/utils/mirror_utils/extensions.dart';
import 'package:dart_net_core_api/utils/mirror_utils/simple_type_reflector.dart';
import 'package:dart_net_core_api/utils/server_utils/any_logger.dart';
import 'package:dart_net_core_api/utils/server_utils/config/config_parser.dart';
import 'package:logging/logging.dart';
import 'package:socket_io_common/socket_io_common.dart';

part 'socket_client.dart';

/// This is the base Socket service.
/// Extend this class to create a custom socket server with custom logic
class SocketService extends Service {
  SocketService({
    this.socketControllers = const [],
    this.connectionPort,
  });

  final Map<String, SocketController> _controllerInstances = {};
  // ignore: unused_field
  late ServiceLocator _serviceLocator;
  final List<Namespace> _namespaces = [];
  bool _isConnectionReady = false;

  SocketController? findControllerByNamespace(String namespace) {
    return _controllerInstances[namespace.fixEndpointPath()];
  }

  /// Override this method and use it as a starting point for
  /// your custom logic
  void onStart() {}

  void _registerControllers(
    ServiceLocator serviceLocator,
    ConfigParser configParser,
  ) {
    _serviceLocator = serviceLocator;
    final namespaces = <String>[];
    for (final controllerType in socketControllers) {
      final reflector = SocketControllerTypeReflector(controllerType);
      final namespace = reflector.socketNamespace;
      if (namespaces.contains(namespace)) {
        throw '''$namespace is already used. If you want
          to create a $SocketController with a different namespace
          use $SocketNamespace on that controller
          like in this example

            @SocketNamespace(path: '/notifications')
            class NotificationSocketController extends SocketController {
              NotificationSocketController();
            } 

        ''';
      } else {
        namespaces.add(namespace);
        _controllerInstances[namespace] = reflector
            .instantiateController(
              serviceLocator: serviceLocator,
              configParser: configParser,
              namespace: namespace,
            )
            .reflectee as SocketController;
      }
    }
  }

  /// a proxy method allowing you to subscribe to events
  void on({
    required String namespace,
    required String event,
    required EventHandler handler,
  }) {
    _checkIfReady();
    final nsp = _namespaces.firstWhereOrNull((n) => n.name == namespace);
    if (nsp != null) {
      nsp.on(event, handler);
    }
  }

  void off({
    required String namespace,
    required String event,
    EventHandler? handler,
  }) {
    _checkIfReady();
    final nsp = _namespaces.firstWhereOrNull((n) => n.name == namespace);
    if (nsp != null) {
      nsp.off(event, handler);
    }
  }

  void _checkIfReady() {
    if (!_isConnectionReady) {
      throw '''
      Please use `onStart()` method as an entry point for your custom logic. 
      This method guarantees you have all of the namespaces ready''';
    }
  }

  @override
  void onReady() {
    _createConnections();
    _isConnectionReady = true;
    onStart();
  }

  Future _createConnections() async {
    if (socketControllers.isEmpty) {
      throw '[$this] You must provide at least one namespace';
    }
    final buffer = StringBuffer();
    io = socket_io.Server();
    for (var controller in _controllerInstances.values) {
      buffer.writeln(controller.namespace);
      final nsp = io.of(controller.namespace);
      _namespaces.add(nsp);
      nsp.on(
        'connection',
        (socket) {
          onConnect(
            socket: socket,
            controller: controller,
          );
        },
      );
      nsp.on('disconnect', (socket) {
        onDisconnect(
          socket: socket,
          controller: controller,
        );
      });
      if (controller.socketMethods.isNotEmpty) {
        for (var method in controller.socketMethods) {
          // print(method.name);
          nsp.on(method.name, (data) {
            _onRemoteMethodCall(
              method,
              data,
            );
          });
        }
      }
    }
    await io.listen(
      _connectionPort,
    );
    if (getConfig<Config>()?.printDebugInfo == true) {
      logGlobal(
        level: Level.INFO,
        message: 'Socket connected on port: $_connectionPort',
      );
      logGlobal(
        level: Level.INFO,
        message: 'Connection namespaces: ${buffer.toString()}',
      );
    }
  }

  Future _onRemoteMethodCall(
    SocketMethod method,
    dynamic data,
  ) async {
    print(data);
    print(data.remoteMethodAnnotations);
  }

  Future _tryCallAuthorization(
    SocketClient client,
    List<SocketAuthorization> authAnnotations,
  ) async {
    for (final annotation in authAnnotations) {
      final result = await annotation.authorize(
        client,
        _serviceLocator,
      );
      if (annotation is SocketJwtAuthorization && result is DateTime) {
        /// in this situation, the date time is the expiration time of the token
        /// I don't think it's the most elegant solution but I'll change it
        /// as soon as I have ti for it
        client._setDisconnectionTime(result);
      }
    }
  }

  Future onConnect({
    required socket_io.Socket socket,
    required SocketController controller,
  }) async {
    final client = SocketClient(
      socket: socket,
    );
    try {
      final authAnnotations = await controller.callMethodByName(
        methodName: '_getAuthAnnotations',
        positionalArguments: [],
      );
      await _tryCallAuthorization(
        client,
        authAnnotations,
      );
    } on String catch (e) {
      client.disconnect(reason: e);
    } catch (e, s) {
      logGlobal(
        level: Level.SEVERE,
        message: e,
        stackTrace: s,
      );
    }
  }

  Future onDisconnect({
    required socket_io.Socket socket,
    required SocketController controller,
  }) async {
    print('DISCONNECTED A CLIENT. Client ID: ${socket.id}');
    // client.on('msg', (data) {
    //   print('data from /some => $data');
    //   client.emit('fromServer', "ok 2");
    // });
  }

  int get _connectionPort {
    if (connectionPort != null) {
      return connectionPort!;
    }
    return 3000;
  }

  SocketConfig? get config {
    return getConfig<SocketConfig>();
  }

  late final socket_io.Server io;

  /// [socketControllers] Pass SocketController types here
  /// they can also use annotation
  final List<Type> socketControllers;

  /// [connectionPort] if you want your socket to connect
  /// on this port, just pass it here.
  /// Otherwise it will try to use a port from socketConfig
  ///
  /// If it also is missing, then it will try to
  /// connect on port 3000 by default
  final int? connectionPort;
}

class SocketConfig implements IConfig {
  int? port;
}
