// ignore_for_file: unused_element

part of 'socket_service.dart';

class SocketClient {
  SocketClient({
    required this.socket,
  });
  final socket_io.Socket socket;

  /// This will be set only for the clients
  /// that require default JWT authorization
  /// To disconnect the client after its Bearer expires
  DateTime? _disconnectAfter;

  bool get isAuthorized {
    if (_disconnectAfter == null) {
      return false;
    }
    return DateTime.now().toUtc().isAfter(
          _disconnectAfter!,
        );
  }

  /// The method is called dynamically from
  /// [SocketJwtAuthorization] annotation (or other that might also need it)
  void _setDisconnectionTime(DateTime value) {
    _disconnectAfter = value;
  }

  void disconnectIfSocketExpired() {
    if (_disconnectAfter == null) {
      return;
    } else {
      if (DateTime.now().toUtc().isAfter(_disconnectAfter!)) {
        disconnect(reason: 'Authorization token expired');
      }
    }
  }

  HttpHeaders get headers {
    return socket.request.headers;
  }

  void disconnect({
    required String reason,
  }) {
    socket.error(reason);
    socket.disconnect(<dynamic, dynamic>{
      'type': DISCONNECT,
    });
    socket.onclose();
  }

  String? get authorizationHeader {
    return headers.authorization;
  }

  String get id {
    return socket.id;
  }
}
