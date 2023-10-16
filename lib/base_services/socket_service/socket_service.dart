import 'package:dart_net_core_api/base_services/socket_service/socket_controller.dart';
import 'package:dart_net_core_api/config.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:socket_io/socket_io.dart' as socket_io;

part 'socket_client.dart';

/// This is the base Socket service.
/// Extend this class to create a custom socket server with custom logic
class SocketService extends Service {
  SocketService({
    this.socketControllers = const [],
    this.connectionPort,
  });

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
    for (var namespace in socketControllers) {
      buffer.writeln(namespace.namespace);
      var nsp = io.of(namespace.namespace);
      nsp.on(
        'connection',
        (socket) {
          onConnect(
            socket: socket,
            namespace: namespace,
          );
        },
      );
      nsp.on('disconnect', (socket) {
        onDisconnect(
          socket: socket,
          namespace: namespace,
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

  Future onConnect({
    required socket_io.Socket socket,
    required SocketController namespace,
  }) async {
    final client = SocketClient(
      socket: socket,
    );
    try {
      await namespace.tryCallAuthorization(client);
    } catch (e) {
      print(e);
    }
    print('CONNECTED A CLIENT ${namespace.namespace}. Client ID: ${client.id}');
    // await Future.delayed(const Duration(seconds: 1));
    // socket.emit('fromServer', "ok");
    // client.on('msg', (data) {
    //   print('data from /some => $data');
    //   client.emit('fromServer', "ok 2");
    // });
  }

  Future onDisconnect({
    required socket_io.Socket socket,
    required SocketController namespace,
  }) async {
    print('DISCONNECTED A CLIENT ${namespace.namespace}. Client ID: ${socket.id}');
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

  /// [socketControllers] the service creates a connection for
  /// every namespace you provide
  final List<SocketController> socketControllers;

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
