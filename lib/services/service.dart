part of '../server.dart';

typedef LazyServiceInitializer = Service Function();

typedef ServiceLocator = Service? Function(Type serviceType);

abstract class Service {

  ConfigParser? _configParser;

  /// WARNING! DO NOT rename this method. This is called 
  /// dynamically using an exact name
  // ignore: unused_element
  void _setConfigParser(ConfigParser value) {
    _configParser = value;
  }

  T? getConfig<T extends IConfig>() {
    return _configParser?.getConfig<T>();
  }
}
