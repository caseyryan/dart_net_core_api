// ignore_for_file: unused_element, unused_field

import 'package:dart_net_core_api/annotations/socket_controller_annotations.dart';
import 'package:dart_net_core_api/server.dart';

/// This is the base class for a server-client socket communication
/// Extend this class to write a custom logic.
/// You can write methods and add annotations to them
abstract class SocketController {
  List<SocketAuthorization> _authAnnotations = [];
  List<SocketAuthorization> _getAuthAnnotations() {
    return _authAnnotations;
  }
  String _namespace = '';
  String get namespace => _namespace;
  late ServiceLocator _serviceLocator;

  /// You can use this method to get a service, 
  /// or pass the [Service] as a parameter to your controller
  /// it's up to you to choose which way is better for you
  T? getService<T extends Service>() {
    return _serviceLocator(T) as T;
  }

  /// This method is called dynamically. Do not remove!.
  /// You won't find any direct calls for it
  /// That's why I used ignore_for_file: unused_element at the top
  void _init(
    List<SocketAuthorization> value,
    String namespace,
    ServiceLocator serviceLocator,
  ) {
    _authAnnotations = value;
    _namespace = namespace;
    _serviceLocator = serviceLocator;
  }

  
}
