// ignore_for_file: unused_element

import 'dart:io';
import 'dart:mirrors';

import 'package:collection/collection.dart';
import 'package:dart_net_core_api/annotations/socket_controller_annotations.dart';
import 'package:dart_net_core_api/config.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/socket_io/lib/socket_io.dart' as socket_io;
import 'package:dart_net_core_api/socket_io/lib/src/namespace.dart';
import 'package:dart_net_core_api/socket_io/lib/src/util/event_emitter.dart';
import 'package:dart_net_core_api/utils/mirror_utils/extensions.dart';
import 'package:dart_net_core_api/utils/mirror_utils/simple_type_reflector.dart';
import 'package:dart_net_core_api/utils/server_utils/any_logger.dart';
import 'package:dart_net_core_api/utils/server_utils/config/config_parser.dart';
import 'package:dart_net_core_api/utils/time_utils.dart';
import 'package:logging/logging.dart';
import 'package:reflect_buddy/reflect_buddy.dart';
import 'package:socket_io_common/socket_io_common.dart';

part 'socket_client.dart';

/// This is the base Socket service.
/// Extend this class to create a custom socket server with custom logic
///
/// [T] if you need a custom [SocketClient] just extend [SocketClient] and
/// pass the type here.
///
/// Notice: your class MUST have a default constructor without params
class SocketService<T extends SocketClient> extends Service {
  SocketService({
    this.socketControllers = const [],
    this.connectionPort,
  });

  final Map<String, SocketControllerTypeReflector> _controllerReflectors = {};
  // ignore: unused_field
  late ServiceLocator _serviceLocator;
  late ConfigParser _configParser;
  final List<Namespace> _namespaces = [];
  bool _isConnectionReady = false;

  final Map<String, SocketClient> _connectedClients = {};

  /// Override this method and use it as a starting point for
  /// your custom logic
  void onStart() {}

  void _registerControllers(
    ServiceLocator serviceLocator,
    ConfigParser configParser,
  ) {
    _serviceLocator = serviceLocator;
    _configParser = configParser;
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
        _controllerReflectors[namespace] = reflector;
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
  Future onReady() async {
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

    for (var controller in _controllerReflectors.entries) {
      buffer.writeln(controller.key);
      final nsp = io.of(controller.key);
      _namespaces.add(nsp);
      nsp.on(
        'connection',
        (socket) {
          onConnect(
            socket: socket,
            controllerReflector: controller.value,
            namespace: controller.key,
          );
        },
      );
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

  Future _tryCallAuthorization(
    SocketClient client,
    List<SocketAuthorization> authAnnotations,
  ) async {
    for (final annotation in authAnnotations) {
      final bearerData = await annotation.authorize(
        client,
        _serviceLocator,
      );
      if (annotation is SocketJwtAuthorization && bearerData is Map) {
        /// in this situation, the date time is the expiration time of the token
        /// I don't think it's the most elegant solution but I'll change it
        /// as soon as I have ti for it
        client._setBearerData(bearerData);
      }
    }
  }

  Future onConnect({
    required socket_io.Socket socket,
    required SocketControllerTypeReflector controllerReflector,
    required String namespace,
  }) async {
    final client = T.instantiate() as SocketClient;
    client._attachSocket(socket);

    _connectedClients[socket.id] = client;
    try {
      final SocketController controllerInstance = controllerReflector
          .instantiateController(
            serviceLocator: _serviceLocator,
            configParser: _configParser,
            namespace: namespace,
            client: client,
          )
          .reflectee;
      final controllerInstanceMirror = reflect(controllerInstance);

      final authAnnotations = await controllerInstance.callMethodByName(
        methodName: '_getAuthAnnotations',
        positionalArguments: [],
      );
      await _tryCallAuthorization(
        client,
        authAnnotations,
      );
      List<SocketMethod> methods = controllerInstance.socketMethods;
      socket.on('disconnect', (data) {
        onDisconnect(socketClient: client);
      });

      for (var method in methods) {
        socket.on(method.name, (data) async {
          try {
            if (data is Map) {
              final positionalArgs = data['positionalArgs'];
              final namedArgs = data['namedArgs'];
              final Object? result = await method.call(
                classInstanceMirror: controllerInstanceMirror,
                positionalArguments: positionalArgs,
                namedArguments: namedArgs,
              );
              if (result != null) {
                if (method.remoteMethod.responseReceiverName != null) {
                  /// if we have a receiver, we need to send a response there
                  final serializedResponse = result.toJson();
                  socket.emit(
                    method.remoteMethod.responseReceiverName!,
                    serializedResponse,
                  );
                }
              }
            }
          } catch (e, s) {
            logGlobal(
              level: Level.SEVERE,
              message: e.toString(),
              stackTrace: s,
            );
          }
        });
      }
      controllerInstance.onConnected();
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
    required SocketClient socketClient,
  }) async {
    socketClient._disconnectControllers();
    // print('DISCONNECTED A CLIENT. Client ID: ${socketClient.id}');
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
  
  @override
  Future dispose() async {}
}

class SocketConfig implements IConfig {
  int? port;
}
