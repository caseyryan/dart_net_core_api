part of 'simple_type_reflector.dart';

/// This reflector is used for json serialization purposes only
/// Only public variables can be serialized / deserialized by default
///
class JsonTypeReflector extends SimpleTypeReflector {
  JsonTypeReflector(super.fromType) {
    if (!constructors.any((e) => e.parameters.isEmpty) && !isPrimitive) {
      throw 'A JSON serializable class must have an empty default constructor';
    }
    for (var kv in _classMirror.declarations.entries) {
      if (kv.value is VariableMirror) {
        final varMirror = kv.value as VariableMirror;
        final hasInclude = varMirror.metadata.any((e) => e.reflectee is JsonInclude);
        final hasIgnore = varMirror.metadata.any((e) => e.reflectee is JsonIgnore);
        if (hasIgnore && hasInclude) {
          throw 'A field cannot be annotated with $JsonInclude and $JsonIgnore at the same time';
        }
        if (!varMirror.isPrivate || hasInclude) {
          if (hasIgnore) {
            continue;
          }
          _variables.add(
            Variable(
              mirror: varMirror,
              symbolicName: kv.key,
            ),
          );
        }
      }
    }
  }

  final List<Variable> _variables = [];

  Object? instanceFromJson(Map json) {
    final instance = _classMirror.newInstance(
      Symbol.empty,
      [],
      {},
    ).reflectee;
    final instanceMirror = reflect(instance);

    for (var kv in json.entries) {
      final variable = tryFindVariableByName(kv.key);
      if (variable != null) {
        if (variable.isPrimitiveType) {
          instanceMirror.setField(
            variable.symbolicName,
            kv.value,
          );
        } else {
          if (variable.isGeneric) {
            if (variable.isList) {
              if (variable.isPrimitiveGenericType) {
                instanceMirror.setField(
                  variable.symbolicName,
                  kv.value as dynamic,
                );
              } else {
                /// Just an additional check
                /// the value in json also must be a list to be able
                /// to be mapped to a list
                if (kv.value is List) {
                  final rawList = kv.value as List;
                  final listGenericType =
                      variable.typeArguments.first._classMirror.reflectedType;

                  final listClassMirror = reflectType(
                    variable.mirror.type.reflectedType,
                  ) as ClassMirror;

                  /// Instantiation of a typed list is necessary
                  /// to avoid type cast exception
                  final c = listClassMirror.getConstructors().firstWhere(
                        (e) => e.simpleName == Symbol('List.from'),
                      );

                  final typedList = listClassMirror.newInstance(
                    c.constructorName,
                    [
                      rawList.map(
                        (e) => listGenericType.fromJson(e),
                      ),
                    ],
                  ).reflectee;

                  instanceMirror.setField(
                    variable.symbolicName,
                    typedList as dynamic,
                  );
                }
              }
            } else {
              /// TODO: Process maps here
              print('not list');
            }
          } else {
            instanceMirror.setField(
              variable.symbolicName,
              variable.convertValueFromJson(
                kv.value,
              ),
            );
          }
        }
      }
    }
    return instance;
  }

  Variable? tryFindVariableByName(
    String name,
  ) {
    return _variables.firstWhereOrNull((v) => v.jsonName == name);
  }
}

class Variable {
  final VariableMirror mirror;
  final Symbol symbolicName;

  String? _name;
  late Type _reflectedType;
  late List<JsonTypeReflector> typeArguments;
  late bool isGeneric = false;
  late List _annotations;
  late bool isList;

  bool get isPrimitiveGenericType {
    if (isGeneric) {
      if (typeArguments.isNotEmpty) {
        return typeArguments.first.isPrimitive;
      }
    }
    return true;
  }

  Object? convertValueFromJson(Map json) {
    return _reflectedType.fromJson(json);
  }

  Variable({
    required this.mirror,
    required this.symbolicName,
  }) {
    _annotations = mirror.metadata.map((e) => e.reflectee).toList();
    _reflectedType = mirror.type.reflectedType;
    isList = mirror.type.qualifiedName == const Symbol('dart.core.List');
    typeArguments = mirror.type.typeArguments
        .map(
          (e) => JsonTypeReflector(e.reflectedType),
        )
        .toList();
    isGeneric = mirror.type.typeArguments.isNotEmpty;
  }

  String get jsonName {
    final JsonName? jsonNameAnnotation = _annotations.firstWhereOrNull(
      (e) => e is JsonName,
    );
    return jsonNameAnnotation?.name ?? name;
  }

  String get name {
    _name ??= symbolicName.toName();
    return _name!;
  }

  bool get isPrimitiveType {
    return _isPrimitiveType(_reflectedType);
  }

  @override
  String toString() {
    return '[Variable: name: $name, type: ${mirror.type.reflectedType}, isPrimitive: $isPrimitiveType, isGeneric: $isGeneric]';
  }
}
