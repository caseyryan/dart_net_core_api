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
    for (var variable in _variables) {
      final valueFromJson = json[variable.jsonName];
      if (variable.isPrimitiveType) {
        variable.checkValueBeforeSetting(valueFromJson);
        instanceMirror.setField(
          variable.symbolicName,
          valueFromJson,
        );
      } else {
        if (variable.isGeneric) {
          // if (variable.isList) {
          if (variable.allGenericTypesPrimitive) {
            variable.checkValueBeforeSetting(valueFromJson);
            instanceMirror.setField(
              variable.symbolicName,
              valueFromJson as dynamic,
            );
          } else {
            /// Just an additional check
            /// the value in json also must be a list to be able
            /// to be mapped to a list
            final classMirror = reflectType(
              variable.mirror.type.reflectedType,
            ) as ClassMirror;

            /// Instantiation of a typed value is necessary
            /// to avoid type cast exception
            final constructor = classMirror.getConstructors().firstWhere(
                  (e) => e.simpleName == variable.defaultConstructorName,
                );
            List<dynamic>? positionalArguments;
            Type genericType;

            if (variable.isList) {
              if (valueFromJson is List) {
                genericType = variable.typeArguments.first._classMirror.reflectedType;
                positionalArguments = [
                  valueFromJson.map(
                    (e) => genericType.fromJson(e),
                  ),
                ];
              }
            } else if (variable.isMap) {
              if (valueFromJson is Map) {
                positionalArguments = [];
                genericType = variable.typeArguments[1]._classMirror.reflectedType;
                for (var kv in valueFromJson.entries) {
                  final value = genericType.fromJson(kv.value);
                  positionalArguments.add({
                    kv.key: value,
                  });
                }
              }
            }
            if (positionalArguments != null) {
              final typedValue = classMirror
                  .newInstance(
                    constructor.constructorName,
                    positionalArguments,
                  )
                  .reflectee;
              variable.checkValueBeforeSetting(typedValue);
              instanceMirror.setField(
                variable.symbolicName,
                typedValue as dynamic,
              );
            }
          }
        } else {
          final value = variable.convertValueFromJson(
            valueFromJson,
          );
          variable.checkValueBeforeSetting(value);
          instanceMirror.setField(
            variable.symbolicName,
            value,
          );
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
  late bool isMap;

  late List<JsonValueValidator> _validators;
  late List<JsonValueConverter> _converters;

  Symbol get defaultConstructorName {
    if (isList) {
      return Symbol('List.from');
    } else if (isMap) {
      return Symbol('Map.from');
    }
    return Symbol.empty;
  }

  bool get allGenericTypesPrimitive {
    if (isGeneric) {
      if (typeArguments.isNotEmpty) {
        return !typeArguments.any((e) => e.isPrimitive);
      }
    }
    return true;
  }

  Object? convertValueFromJson(Map json) {
    return _reflectedType.fromJson(json);
  }

  /// Applies conversion and validation in a correct order
  void checkValueBeforeSetting(dynamic value) {
    for (var converter in _converters) {
      value = converter.convert(value);
    }
    _validateValue(value);
  }

  /// This is called when trying to set a field value
  void _validateValue(dynamic value) {
    for (var v in _validators) {
      v.validate(
        fieldName: jsonName,
        actualValue: value,
      );
    }
  }

  Variable({
    required this.mirror,
    required this.symbolicName,
  }) {
    _annotations = mirror.metadata.map((e) => e.reflectee).toList();
    _validators = _annotations.whereType<JsonValueValidator>().toList();
    _converters = _annotations.whereType<JsonValueConverter>().toList();
    _reflectedType = mirror.type.reflectedType;
    isList = mirror.type.qualifiedName == const Symbol('dart.core.List');
    isMap = mirror.type.qualifiedName == const Symbol('dart.core.Map');
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
