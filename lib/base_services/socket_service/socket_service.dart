// ignore_for_file: unused_element

import 'dart:io';

import 'package:dart_net_core_api/annotations/socket_controller_annotations.dart';
import 'package:dart_net_core_api/base_services/socket_service/socket_controller.dart';
import 'package:dart_net_core_api/config.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/socket_io/lib/socket_io.dart' as socket_io;
import 'package:dart_net_core_api/utils/extensions.dart';
import 'package:dart_net_core_api/utils/mirror_utils/extensions.dart';
import 'package:dart_net_core_api/utils/mirror_utils/simple_type_reflector.dart';
import 'package:dart_net_core_api/utils/server_utils/config/config_parser.dart';
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

  SocketController? findControllerByNamespace(String namespace) {
    return _controllerInstances[namespace.fixEndpointPath()];
  }

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

  @override
  void onReady() {
    _createConnections();
  }

  Future _createConnections() async {
    if (socketControllers.isEmpty) {
      throw '[$this] You must provide at least one namespace';
    }
    final buffer = StringBuffer();
    io = socket_io.Server();
    for (var controller in _controllerInstances.values) {
      buffer.writeln(controller.namespace);
      var nsp = io.of(controller.namespace);
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
    }
    await io.listen(
      _connectionPort,
    );
    if (getConfig<Config>()?.printDebugInfo == true) {
      print('Socket connected on port: $_connectionPort');
      print('Connection namespaces: ${buffer.toString()}');
    }
  }

  Future _tryCallAuthorization(
    SocketClient client,
    List<SocketAuthorization> authAnnotations,
  ) async {
    for (final annotation in authAnnotations) {
      await annotation.authorize(
        client,
        _serviceLocator,
      );
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
    } catch (e) {
      /// TODO: Replace with logger
      print(e);
    }
    // print('CONNECTED A CLIENT ${namespace.namespace}. Client ID: ${client.id}');
    // await Future.delayed(const Duration(seconds: 1));
    // socket.emit('fromServer', "ok");
    // client.on('msg', (data) {
    //   print('data from /some => $data');
    //   client.emit('fromServer', "ok 2");
    // });
  }

  Future onDisconnect({
    required socket_io.Socket socket,
    required SocketController controller,
  }) async {
    // print('DISCONNECTED A CLIENT ${namespace.namespace}. Client ID: ${socket.id}');
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
