part of 'simple_type_reflector.dart';

/// This reflector is used for json serialization purposes only
/// Only public variables can be serialized / deserialized by default
///
class JsonTypeReflector extends SimpleTypeReflector {
  JsonTypeReflector(super.fromType) {
    if (!isPrimitive) {
      if (!_classMirror.isList && !_classMirror.isMap) {
        if (!constructors.any((e) => e.parameters.where((p) => !p.isOptional).isEmpty)) {
          throw 'A JSON serializable class must have an empty default constructor';
        }
      }
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

  List<Object?> _jsonListToTypedList({
    required List jsonList,
    required Type genericType,
  }) {
    return jsonList
        .map(
          (e) => genericType.fromJson(e),
        )
        .toList();
  }

  Object? instanceFromJson(Map json) {
    if (_classMirror.isPrimitiveType) {
      return json;
    }
    Object? instance;
    // if (_classMirror.isList) {
    //   print(json);
    // } else {
    instance = _classMirror.newInstance(
      Symbol.empty,
      [],
      {},
    ).reflectee;
    // }
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

            if (variable.isList) {
              if (valueFromJson is List) {
                positionalArguments = [
                  _jsonListToTypedList(
                    genericType: variable.mirror.type.typeArguments.first.reflectedType,
                    jsonList: valueFromJson,
                  ),
                ];
              }
            } else if (variable.isMap) {
              if (valueFromJson is Map) {
                final innerClassMirror =
                    variable.mirror.type.typeArguments[1] as ClassMirror;
                if (innerClassMirror.isList) {
                  throw 'Inner Lists are not supported "${variable.jsonName}"';
                } else if (innerClassMirror.isMap) {
                  throw 'Inner Maps are not supported "${variable.jsonName}"';
                } else {
                  final type = variable.mirror.type.typeArguments[1].reflectedType;

                  positionalArguments = [
                    {
                      variable.jsonName: type.fromJson(valueFromJson),
                    },
                  ];
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

  Variable({
    required this.mirror,
    required this.symbolicName,
  }) {
    _annotations = mirror.metadata.map((e) => e.reflectee).toList();
    _validators = _annotations.whereType<JsonValueValidator>().toList();
    _converters = _annotations.whereType<JsonValueConverter>().toList();
    _reflectedType = mirror.type.reflectedType;
    isPrivate = mirror.isPrivate;
    isList = mirror.type.qualifiedName == const Symbol('dart.core.List');
    isMap = mirror.type.qualifiedName == const Symbol('dart.core.Map');
    typeArguments = mirror.type.typeArguments
        .map(
          (e) => JsonTypeReflector(e.reflectedType),
        )
        .toList();
    isGeneric = mirror.type.typeArguments.isNotEmpty;
    final nameAnnotations = _annotations.whereType<JsonName>();
    if (nameAnnotations.isNotEmpty) {
      if (nameAnnotations.length > 1) {
        throw 'A field cannot have more that one $JsonName annotation. "$name" has ${nameAnnotations.length}';
      }
      _jsonName = nameAnnotations.first;
    }
  }

  final VariableMirror mirror;
  final Symbol symbolicName;

  String? _name;
  late Type _reflectedType;
  late List<JsonTypeReflector> typeArguments;
  late bool isGeneric = false;
  late List _annotations;
  late bool isList;
  late bool isMap;
  late bool isPrivate;

  late List<JsonValueValidator> _validators;
  late List<JsonValueConverter> _converters;

  JsonName? _jsonName;

  Symbol get defaultConstructorName {
    if (isList) {
      return const Symbol('List.from');
    } else if (isMap) {
      return const Symbol('Map.from');
    }
    return Symbol.empty;
  }
  
  bool get allGenericTypesPrimitive {
    if (isGeneric) {
      if (typeArguments.isNotEmpty) {
        return !typeArguments.any((e) => !e.isPrimitive);
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

  

  bool get isJsonIgnored {
    return _annotations.whereType<JsonIgnore>().isNotEmpty || (isPrivate && !isJsonIncluded);
  }

  bool get isJsonIncluded {
    return _annotations.whereType<JsonInclude>().isNotEmpty ;
  }

  bool get isBsonIgnored {
    return _annotations.whereType<BsonIgnore>().isNotEmpty;
  }

  bool get hasOverriddenName {
    return _jsonName != null;
  }

  String get jsonName {
    return _jsonName?.name ?? name;
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
