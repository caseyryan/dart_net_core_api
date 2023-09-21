import 'dart:convert' as convert;
import 'dart:mirrors';

import 'package:collection/collection.dart';
import 'package:dart_net_core_api/annotations/field_annotations.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

import '../get_annotation_instance.dart';

final _jsonIgnoreMirror = reflectClass(JsonIgnore);
final _bsonIgnoreMirror = reflectClass(BsonIgnore);

typedef DateTimeConverter = T Function<T>(DateTime dateTime);

String defaultDateTimeConverter<String>(
  DateTime dateTime,
) {
  return dateTime.toIso8601String() as String;
}

abstract class JsonSerializer {
  const JsonSerializer();

  Map<String, dynamic> toMap(dynamic instance);
  Map<String, dynamic> toMongoMap(
    dynamic instance, {
    KeyNameConverter? keyNameConverter,
  });
  String toJson(dynamic instance);

  dynamic deserializeFromMongoMap(
    Map? data,
    Type type,
  );
}

/// Can serialize normal dart classes to json
/// You don'e need to add any attributes to a class for
/// it to become serializable. All classes are serializable by default
/// in can serialize public variables and getters.
/// If, for some reason, you don't want to serialize some field or a
/// variable, just mark it with @JsonIgnore() annotation and
/// the serializer will skip it
/// [beautifyResponse] if true, the output will be formatted
/// the output of toJson() will be printed
/// with indents and separate lines
/// [dateTimeConverter] a function that accepts DateTime as input
/// and returns a value specified by T generic type
/// IMPORTANT! T must be json serializable
/// [defaultKeyNameConverter] a class extending
/// KeyNameConverter. These classes can also be used as annotations on
/// classes, fields, and getters that are supposed to be serialized to json
class DefaultJsonSerializer extends JsonSerializer {
  /// [beautifyResponse] if true, the output will be formatted with
  /// indents
  const DefaultJsonSerializer({
    this.beautifyResponse = true,
    this.dateTimeConverter = defaultDateTimeConverter,
    this.defaultKeyNameConverter,
  });

  final bool beautifyResponse;
  final DateTimeConverter dateTimeConverter;

  /// Top level key name converter. If there is an
  /// annotation on a class or field or a variable
  /// this will be overriden
  final KeyNameConverter? defaultKeyNameConverter;

  @override
  String toJson(dynamic instance) {
    final map = toMap(instance);
    if (beautifyResponse) {
      return const convert.JsonEncoder.withIndent('  ').convert(map);
    }
    return convert.jsonEncode(map);
  }

  @override
  dynamic deserializeFromMongoMap(
    dynamic data,
    Type type,
  ) {
    if (data == null) {
      return null;
    }

    if (!_isPrimitiveType(type)) {
      final classMirror = reflectType(type) as ClassMirror;
      final constructor = classMirror.getConstructors().first as MethodMirror;
      final InstanceMirror mirror = classMirror.newInstance(
        constructor.constructorName,
        [],
      );
      if (data is Map) {
        for (var kv in data.entries) {
          try {
            final fieldName = kv.key.toString().replaceFirst('_', '');

            Object? value = kv.value;
            if (value is mongo.ObjectId) {
              value = value.toHexString();
            }
            if (value is List) {
              /// если поле - дженерик лист и у него не стандартный тип внутри
              /// то надо инстанциировать инстанцы этого типа и уже их затолкать в
              /// ответ
              final listGenericType = classMirror.getListGenericType(fieldName);
              if (listGenericType != null) {
                
                final listType = classMirror.getFullType(fieldName);
                if (listType != null) {
                  final listClassMirror = reflectType(listType) as ClassMirror;
                  final c = listClassMirror.getConstructors().first as MethodMirror;
                  final typedList = listClassMirror.newInstance(
                    c.constructorName,
                    [],
                  ).reflectee;

                  /// здесь value это List
                  for (var fieldValue in value) {
                    var innerValue = deserializeFromMongoMap(
                      fieldValue,
                      listGenericType,
                    );
                    if (innerValue is mongo.ObjectId) {
                      innerValue = innerValue.toHexString();
                    }
                    typedList.add(innerValue);
                  }
                  value = typedList;
                }
              }
            } else if (value is Map) {
              final mapGenericTypes = classMirror.getMapGenericTypes(fieldName);
              if (mapGenericTypes != null) {
                final mapType = classMirror.getFullType(fieldName);
                if (mapType != null) {
                  final mapClassMirror = reflectType(mapType) as ClassMirror;
                  final c = mapClassMirror.getConstructors().first as MethodMirror;
                  final typedMap = mapClassMirror.newInstance(
                    c.constructorName,
                    [],
                  ).reflectee;
                  for (var kv in value.entries) {
                    final key = deserializeFromMongoMap(
                      kv.key,
                      mapGenericTypes[0],
                    );
                    final mapValue = deserializeFromMongoMap(
                      kv.value,
                      mapGenericTypes[1],
                    );
                    typedMap[key] = mapValue;
                  }
                  value = typedMap;
                }
              }
            }
            
            mirror.setField(
              Symbol(fieldName),
              value,
            );
          } catch (e) {
            print(e);
          }
        }
      }
      return mirror.reflectee;
    }
    return data;
  }

  @override
  Map<String, dynamic> toMap(
    dynamic instance, [
    KeyNameConverter? keyNameConverter,
  ]) {
    final Map<String, dynamic> map = {};
    if (instance != null) {
      final instanceMirror = reflect(instance);
      final classMirror = reflectClass(instance.runtimeType);

      ///
      final customKeyNameConverter = getAnnotationInstanceOrNull<KeyNameConverter>(
            classMirror.metadata,
          ) ??
          keyNameConverter ??
          defaultKeyNameConverter;

      for (var declare in classMirror.declarations.values) {
        if (!declare.isPrivate) {
          if (hasJsonIgnore(declare)) {
            continue;
          }
          final isGetter = declare is MethodMirror && declare.isGetter;
          if (isGetter) {
            continue;
          }
          if (declare is VariableMirror) {
            if (declare.isStatic || declare.isConst) {
              continue;
            }
            var name = MirrorSystem.getName(declare.simpleName);
            final reflectee = instanceMirror.getField(Symbol(name)).reflectee;
            // if (name == 'simplified') {
            //   // print(reflectee);
            // }
            final value = processValue(
              reflectee,
              keyNameConverter: customKeyNameConverter,
            );

            /// Individual fields can have a separate
            /// key name converter. This will override the class
            /// level converter
            final fieldScopeNameConverter = getAnnotationInstanceOrNull<KeyNameConverter>(
              declare.metadata,
            );
            if (fieldScopeNameConverter != null) {
              name = fieldScopeNameConverter.convert(name);
            } else {
              if (customKeyNameConverter != null) {
                name = customKeyNameConverter.convert(name);
              }
            }

            map[name] = value;
          }
        }
      }
    }
    return map;
  }

  @override
  Map<String, dynamic> toMongoMap(
    dynamic instance, {
    KeyNameConverter? keyNameConverter,
  }) {
    final Map<String, dynamic> map = {};
    if (instance != null) {
      final instanceMirror = reflect(instance);
      final classMirror = reflectClass(instance.runtimeType);

      ///
      final customKeyNameConverter = getAnnotationInstanceOrNull<KeyNameConverter>(
            classMirror.metadata,
          ) ??
          keyNameConverter ??
          defaultKeyNameConverter;

      for (var declare in classMirror.declarations.values) {
        if (!declare.isPrivate) {
          if (hasBsonIgnore(declare)) {
            continue;
          }
          final isGetter = declare is MethodMirror && declare.isGetter;
          if (isGetter) {
            continue;
          }
          if (declare is VariableMirror) {
            if (declare.isConst || declare.isStatic) {
              continue;
            }
            var name = MirrorSystem.getName(declare.simpleName);
            // print('NAME $name');
            final fieldMirror = instanceMirror.getField(Symbol(name));
            dynamic value = processValue(
              fieldMirror.reflectee,
              keyNameConverter: customKeyNameConverter,
              convertDateToString: false,
            );
            if (value == null) {
              continue;
            }
            if (name == 'id') {
              name = '_id';
              value = mongo.ObjectId.fromHexString(
                value.toString(),
              );
            }

            map[name] = value;
          }
        }
      }
    }
    return map;
  }

  bool hasJsonIgnore(DeclarationMirror declarationMirror) {
    for (var instanceMirror in declarationMirror.metadata) {
      if (instanceMirror.type.isSubclassOf(_jsonIgnoreMirror)) {
        return true;
      }
    }
    return false;
  }
  bool hasBsonIgnore(DeclarationMirror declarationMirror) {
    for (var instanceMirror in declarationMirror.metadata) {
      if (instanceMirror.type.isSubclassOf(_bsonIgnoreMirror)) {
        return true;
      }
    }
    return false;
  }

  dynamic processValue(
    dynamic value, {
    KeyNameConverter? keyNameConverter,
    bool convertDateToString = true,
  }) {
    if (value == null) {
      return value;
    }
    final type = value.runtimeType;
    if (type == double || type == num || type == int || type == bool || type == String) {
      return value;
    } else if (type == DateTime) {
      if (!convertDateToString) {
        return value;
      }
      return dateTimeConverter.call(value as DateTime);
    } else if (value is List) {
      return value
          .map((e) => processValue(
                e,
                keyNameConverter: keyNameConverter,
                convertDateToString: convertDateToString,
              ))
          .toList();
    } else if (value is Map) {
      return value.map((key, value) {
        return MapEntry(
          key,
          processValue(
            value,
            keyNameConverter: keyNameConverter,
            convertDateToString: convertDateToString,
          ),
        );
      });
    }
    try {
      return toMap(
        value,
        keyNameConverter,
      );
    } catch (e) {
      print(e);
    }
    return value;
  }
}

extension _SymbolExtension on Symbol {
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

final List<Type> _standardTypes = [
  String,
  Map,
  int,
  bool,
  double,
  dynamic,
];
bool _isPrimitiveType(Type type) {
  return _standardTypes.any((e) => type == e);
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
          if (_isPrimitiveType(reflectedType)) {
            // return null;
          }
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
          if (_isPrimitiveType(firstType) && _isPrimitiveType(secondType)) {
            // return null;
          }
          return [firstType, secondType];
        }
      }
    }
    return null;
  }

  /// возвращает весь тип списка, включая дженерик часть
  /// типа List<SomeType> или даже Map<SomeType, SomeOtherType>
  /// работает как для списков, так и для мап
  Type? getFullType(String fieldName) {
    final field = declarations.entries.firstWhereOrNull((kv) {
      final key = kv.key.toName();
      return key == fieldName;
    });
    if (field != null) {
      if (field.value is VariableMirror) {
        final reflectedType =
            ((field.value as VariableMirror).type as ClassMirror).reflectedType;
        return reflectedType;
      }
    }
    return null;
  }
}
