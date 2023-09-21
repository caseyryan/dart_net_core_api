import 'dart:mirrors';

import 'package:dart_net_core_api/utils/mirror_utils/extensions.dart';

T instantiateGeneric<T>() {
  final ClassMirror classMirror = reflectClass(T);
  final constructor = classMirror.getConstructors().first as MethodMirror;
  final instance = classMirror.newInstance(
    constructor.constructorName,
    [],
  ).reflectee;
  return instance;
}
