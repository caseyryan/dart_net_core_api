// ignore_for_file: prefer_final_fields, unnecessary_getters_setters

part of '../server.dart';

typedef LazyServiceInitializer = Service Function();

/// Pass [T] or [serviceType]. The parameter is used to
/// simplify type case when using reflection
typedef ServiceLocator = T? Function<T extends Service>([
  Type? serviceType,
]);

abstract class Service extends Configurable {

  /// If service is not singleton, it will be disposed 
  /// after the controller that uses is is disposed 
  bool _isSingleton = false;
  bool get isSingleton => _isSingleton;
  set isSingleton(bool value) {
    _isSingleton = value;
  }

  /// Use this method as a starting point for your service.
  /// When it's called you can be sure that the config is already
  /// attached to a service
  FutureOr onReady();

  FutureOr dispose();

  

  String get environment {
    return _configParser?.environment ?? '';
  }
}
