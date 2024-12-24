part of '../../../server.dart';



abstract class Configurable {
  ConfigParser? _configParser;
  ConfigParser? get configParser => _configParser;
  ServiceLocator? _serviceLocator;
  ServiceLocator? get serviceLocator => _serviceLocator;
  bool _isReady = false;

// ignore: unused_element
  void _setConfigParser(ConfigParser value) {
    // print('_setConfigParser called on $runtimeType ($hashCode) with a value of $value');
    if (_configParser != null) {
      /// This check is required because this method may be called
      /// several times but we don't want [onReady] to be called again
      return;
    }
    _configParser = value;
    _checkIfReady();
    
  }

  void _checkIfReady() {
    if (_isReady) {
      return;
    }
    if (_configParser != null && _serviceLocator != null) {
      _isReady = true;
      onConfigurableReady();
    }
  }

  T? getConfig<T extends IConfig>() {
    return _configParser?.getConfig<T>();
  }

  void onConfigurableReady() {
    print(getConfig<Config>());
  }

  // ignore: unused_element
  void _setServiceLocator(ServiceLocator value) {
    _serviceLocator = value;
    _checkIfReady();
  }

  T? getService<T extends Service>() {
    return _serviceLocator!<T>();
  }
}
