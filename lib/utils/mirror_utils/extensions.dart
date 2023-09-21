import 'dart:mirrors';

import 'package:collection/collection.dart';

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


extension ClassMirrorExtension on ClassMirror {
  List<DeclarationMirror> getConstructors() {
    final constructors = declarations.values
        .where(
          (declare) => declare is MethodMirror && declare.isConstructor,
        )
        .toList();
    return constructors;
  }

  Type? getListGenericType(String fieldName) {
    final field = declarations.entries.firstWhereOrNull((kv) {
      final key = kv.key.toName();
      return key == fieldName;
    });
    if (field != null) {
      if (field.value is VariableMirror) {
        final type = (field.value as VariableMirror).type as ClassMirror;
        if (type.typeArguments.isNotEmpty) {
          final reflectedType = type.typeArguments.first.reflectedType;
          return reflectedType;
        }
      }
    }
    return null;
  }

  List<Type>? getMapGenericTypes(String fieldName) {
    final field = declarations.entries.firstWhereOrNull((kv) {
      final key = kv.key.toName();
      return key == fieldName;
    });
    if (field != null) {
      if (field.value is VariableMirror) {
        final type = (field.value as VariableMirror).type as ClassMirror;
        if (type.typeArguments.length == 2) {
          final firstType = type.typeArguments[0].reflectedType;
          final secondType = type.typeArguments[1].reflectedType;
          return [firstType, secondType];
        }
      }
    }
    return null;
  }

}