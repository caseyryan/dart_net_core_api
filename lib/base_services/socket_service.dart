import 'package:dart_net_core_api/config.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:socket_io/socket_io.dart' as socket_io;

/// This is the base Socket service.
/// Extend this class to create a custom socket server with custom logic
class SocketService extends Service {
  SocketService({
    this.namespaces = const [],
    this.connectionPort,
    this.allowDefaultNamespace,
  });

  @override
  void onReady() {
    _createConnections();
  }

  Future _createConnections() async {
    if (namespaces.isEmpty && !_allowDefaultNamespace) {
      throw '[$this] You must provide at least one namespace or set allowDefaultNamespace to `true`';
    }
    final buffer = StringBuffer();
    io = socket_io.Server();
    if (_allowDefaultNamespace) {
      buffer.writeln('/');
      io.on(
        'connection',
        (client) {
          onConnection(
            client: client,
            namespace: '/',
          );
        },
      );
    }
    for (var nsString in namespaces) {
      buffer.writeln(nsString);
      var nsp = io.of(nsString);
      nsp.on(
        'connection',
        (client) {
          onConnection(
            client: client,
            namespace: nsString,
          );
        },
      );
    }
    await io.listen(
      _connectionPort,
    );
    if (getConfig<Config>()?.printDebugInfo == true) {
      print('Socket connected on port: $_connectionPort');
      print('Connection namespaces: ${buffer.toString()}');
    }
  }

  Future onConnection({
    required client,
    required String namespace,
  }) async {
    print('connection $namespace');
    // client.on('msg', (data) {
    //   print('data from /some => $data');
    //   client.emit('fromServer', "ok 2");
    // });
  }

  bool get _allowDefaultNamespace {
    if (allowDefaultNamespace != null) {
      return allowDefaultNamespace!;
    }
    return config?.allowDefaultNamespace == true;
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

  /// [namespaces] the service creates a connection for
  /// every namespace you provide
  final List<String> namespaces;

  /// [connectionPort] if you want your socket to connect
  /// on this port, just pass it here.
  /// Otherwise it will try to use a port from socketConfig
  ///
  /// If it also is missing, then it will try to
  /// connect on port 3000 by default
  final int? connectionPort;

  /// this will allow a socket server to connect
  /// on the default namespace even if no namespace is provided
  final bool? allowDefaultNamespace;
}

class SocketConfig implements IConfig {
  int? port;
  bool? allowDefaultNamespace;
}
