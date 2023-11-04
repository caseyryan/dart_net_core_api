// ignore_for_file: unused_element

part of 'socket_service.dart';

class SocketClient {
  final List<SocketController> _attachedControllers = [];

  void attachController(SocketController controller) {
    if (!_attachedControllers.contains(controller)) {
      _attachedControllers.add(controller);
    }
  }

  void _disconnectControllers() {
    for (var controller in _attachedControllers) {
      controller.onDisconnected();
      controller.dispose();
    }
  }

  SocketClient({
    required socket_io.Socket socket,
  }) {
    _socket = socket;
  }
  late socket_io.Socket _socket;

  @override
  bool operator ==(covariant SocketClient other) {
    return other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }

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

  void disconnectIfTokenExpired() {
    if (_disconnectAfter == null) {
      return;
    } else {
      if (DateTime.now().toUtc().isAfter(_disconnectAfter!)) {
        disconnect(reason: 'Authorization token expired');
      }
    }
  }

  HttpHeaders get headers {
    return _socket.request.headers;
  }

  void disconnect({
    required String reason,
  }) {
    _socket.error(reason);
    _socket.disconnect(<dynamic, dynamic>{
      'type': DISCONNECT,
    });
    _socket.onclose();
  }

  String? get authorizationHeader {
    return headers.authorization;
  }

  String get id {
    return _socket.id;
  }
}
