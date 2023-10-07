part of '../server.dart';

typedef LazyServiceInitializer = IService Function();

typedef ServiceLocator = IService? Function(Type serviceType);

abstract class IService {}