part of 'socket_service.dart';

class SocketClient {
  SocketClient({
    required this.socket,
  });
  final socket_io.Socket socket;

  String get id {
    return socket.id;
  }
}
