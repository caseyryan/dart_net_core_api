part of '../server.dart';

typedef LazyServiceInitializer = Service Function();

typedef ServiceLocator = Service? Function(Type serviceType);

abstract class Service {


  ConfigParser? _configParser;

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
  void onReady();

  T? getConfig<T extends IConfig>() {
    return _configParser?.getConfig<T>();
  }
}
