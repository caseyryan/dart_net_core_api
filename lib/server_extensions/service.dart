part of '../server.dart';

typedef LazyServiceInitializer = Service Function();

typedef ServiceLocator = Service? Function(Type serviceType);

abstract class Service {}