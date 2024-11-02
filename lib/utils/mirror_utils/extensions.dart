import 'dart:async';
import 'dart:mirrors';

import 'package:dart_net_core_api/utils/server_utils/any_logger.dart';
import 'package:logging/logging.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

extension TypeExtension on Type {
  bool implementsInterface<T>() {
    final reflection = reflectType(this) as ClassMirror;
    return reflection.superinterfaces.any((e) {
      return e.reflectedType == T;
    });
  }

  bool isSubclassOf<T>() {
    final classMirror = reflectType(this) as ClassMirror;
    return classMirror.isSubclassOf(reflectType(T) as ClassMirror);
  }

  T instantiate<T>([
    List<dynamic> positionalArguments = const [],
    Map<Symbol, dynamic> namedArguments = const <Symbol, dynamic>{},
  ]) {
    final classMirror = reflectType(this) as ClassMirror;
    return classMirror
        .newInstance(
          Symbol.empty,
          [],
          namedArguments,
        )
        .reflectee;
  }
}

extension ObjectExtension on Object {
  String toLoggerName() {
    return runtimeType.toString();
  }

  bool toBool() {
    final stringVal = toString().toLowerCase();
    return stringVal == 'true' || stringVal == '1' || stringVal == 'yes' || stringVal == 'y' || stringVal == '+';
  }

  /// This can be used to call even private methods
  /// It doesn't care for a method visibility
  FutureOr callMethodByName({
    required String methodName,
    required List<dynamic> positionalArguments,
    Map<Symbol, dynamic> namedArguments = const <Symbol, dynamic>{},
  }) async {
    final classMirror = _findClassContainingMethod(
      methodName: methodName,
      runtimeType: runtimeType,
    );
    if (classMirror != null) {
      for (var kv in classMirror.declarations.entries) {
        if (kv.value is MethodMirror) {
          final MethodMirror methodMirror = kv.value as MethodMirror;
          final name = methodMirror.simpleName.toName();
          if (name == methodName) {
            final instanceMirror = reflect(this);
            return instanceMirror
                .invoke(
                  methodMirror.simpleName,
                  positionalArguments,
                  namedArguments,
                )
                .reflectee;
          }
        }
      }
    }
  }

  ClassMirror? _findClassContainingMethod({
    required String methodName,
    required Type runtimeType,
  }) {
    final classMirror = reflectType(runtimeType) as ClassMirror;
    for (var kv in classMirror.declarations.entries) {
      if (kv.value is MethodMirror) {
        final MethodMirror methodMirror = kv.value as MethodMirror;
        final methodSimpleName = methodMirror.simpleName.toName();
        if (methodSimpleName == methodName) {
          return classMirror;
        }
      }
    }
    if (classMirror.superclass != null) {
      return _findClassContainingMethod(
        methodName: methodName,
        runtimeType: classMirror.superclass!.reflectedType,
      );
    }
    return null;
  }

  List<T> findAllInstancesOfType<T>() {
    final list = <T>[];
    try {
      if (runtimeType.implementsInterface<T>()) {
        list.add(this as T);
      }
      final instanceMirror = reflect(this);

      for (var kv in instanceMirror.type.declarations.entries) {
        if (kv.value is VariableMirror) {
          final variableMirror = kv.value as VariableMirror;
          Object? rawValue = instanceMirror
              .getField(
                variableMirror.simpleName,
              )
              .reflectee;
          if (rawValue is T) {
            list.add(rawValue);
          } else if (rawValue is List) {
            final list = rawValue;
            list.addAll(list.map((Object? e) => e?.findAllInstancesOfType<T>()));
          } else if (rawValue is Map) {
            final list = rawValue.values.toList();
            list.addAll(list.map((Object? e) => e?.findAllInstancesOfType<T>()));
          }
        }
      }
    } catch (e, s) {
      logGlobal(
        level: Level.SEVERE,
        message: e.toString(),
        stackTrace: s,
      );
    }

    return list;
  }
}
