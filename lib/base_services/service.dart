// ignore_for_file: prefer_final_fields, unnecessary_getters_setters

part of '../server.dart';

typedef LazyServiceInitializer = Service Function();

/// Pass [T] or [serviceType]. The parameter is used to
/// simplify type case when using reflection
typedef ServiceLocator = T? Function<T extends Service>([
  Type? serviceType,
]);

abstract class Service {
  ConfigParser? _configParser;

  /// If service is not singleton, it will be disposed 
  /// after the controller that uses is is disposed 
  bool _isSingleton = false;
  bool get isSingleton => _isSingleton;
  set isSingleton(bool value) {
    _isSingleton = value;
  }

  /// WARNING! DO NOT rename this method. This is called
  /// dynamically using an exact name
  // ignore: unused_element
  void _setConfigParser(ConfigParser value) {
    if (_configParser != null) {
      /// This check is required because this method may be called
      /// several times but we don't want [onReady] to be called again
      return;
    }
    _configParser = value;
  }

  /// Use this method as a starting point for your service.
  /// When it's called you can be sure that the config is already
  /// attached to a service
  FutureOr onReady();

  FutureOr dispose();

  T? getConfig<T extends IConfig>() {
    return _configParser?.getConfig<T>();
  }
}
