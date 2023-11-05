// ignore_for_file: unused_element

part of 'socket_service.dart';

class SocketClient {
  SocketClient();
  late socket_io.Socket _socket;

  void _attachSocket(socket_io.Socket value) {
    _socket = value;
  }

  final List<SocketController> _attachedControllers = [];

  /// This will be filled after authorization, if your controller
  /// is authorized. This can be used for different purposes e.g.
  /// attaching a user data to the [SocketClient]
  Map _bearerData = {};
  Map get bearerData => _bearerData;

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

  /// Use this method to send responses to a client
  /// This will make sure the client token has not expired
  /// before sending anything and will disconnect the client
  /// if it has
  void emitWithAcknowledgements(
    String event,
    dynamic data, {
    Function? ack,
    bool binary = false,
  }) {
    if (isAuthorized) {
      _socket.emitWithAck(
        event,
        data,
        ack: ack,
        binary: binary,
      );
    } else {
      disconnectIfTokenExpired();
    }
  }

  void emit(
    String event, [
    dynamic data,
  ]) {
    emitWithAcknowledgements(
      event,
      data,
    );
  }

  void emitWithBinary(
    String event, [
    dynamic data,
  ]) {
    emitWithAcknowledgements(
      event,
      data,
      binary: true,
    );
  }

  void on(String event, EventHandler handler) {
    _socket.on(event, handler);
  }

  /// This function binds the [handler] as a listener to the first
  /// occurrence of the [event]. When [handler] is called once,
  /// it is removed.
  void once(String event, EventHandler handler) {
    _socket.once(event, handler);
  }

  /// This function attempts to unbind the [handler] from the [event]
  void off(String event, [EventHandler? handler]) {
    _socket.off(event, handler);
  }

  /// This function unbinds all the handlers for all the events.
  void clearListeners() {
    _socket.clearListeners();
  }

  /// Returns whether the event has registered.
  bool hasListeners(String event) {
    return _socket.hasListeners(event);
  }

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
  void _setBearerData(Map value) {
    _bearerData = value;
    final expSeconds = value['exp'] * 1000;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      expSeconds,
    );
    _disconnectAfter = expiresAt;
  }

  void disconnectIfTokenExpired() {
    if (!isAuthorized) {
      disconnect(reason: 'Authorization token expired');
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
