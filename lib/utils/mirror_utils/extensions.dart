import 'dart:mirrors';

extension SymbolExtension on Symbol {
  static final RegExp _regExp = RegExp(r'(?<=Symbol\(")[a-zA-Z0-9_]+');

  String toName() {
    final name = toString();
    final match = _regExp.firstMatch(name);
    if (match == null) {
      return '';
    }
    return name.substring(
      match.start,
      match.end,
    );
  }
}

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
}

extension ObjectExtension on Object {
  /// This hack can be used to call private methods
  void callMethodRegardlessOfVisibility({
    required String methodName,
    required List<dynamic> positionalArguments,
    Map<Symbol, dynamic> namedArguments = const <Symbol, dynamic>{},
  }) {
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
            instanceMirror.invoke(
              methodMirror.simpleName,
              positionalArguments,
              namedArguments,
            );
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
      print(e);
      print(s);
    }

    return list;
  }
}
