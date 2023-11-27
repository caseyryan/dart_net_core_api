import 'dart:mirrors';

import 'package:dart_net_core_api/utils/extensions/extensions.dart';
import 'package:dart_net_core_api/utils/json_utils/value_converters/mongo_id_converter.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

extension ObjectExtensions on Object {

  ObjectId? toObjectId() {
    return toBson() as ObjectId?;
  }

  /// A value similar to a regular JSON but MongoDB compatible
  Object? toBson({
    bool includeNullValues = false,
    JsonKeyNameConverter? keyNameConverter,
  }) {
    if (runtimeType.isPrimitive) {
      if (this is String) {
        final String str = this as String;
        if (str.isMatchingObjectId()) {
          return ObjectId.fromHexString(str);
        }
      }
      return this;
    } else if (this is ObjectId) {
      return this;
    } else if (this is Map) {
      final newMap = {};
      final curMap = this as Map;
      for (var kv in curMap.entries) {
        newMap[(kv.key as Object).toBson()] = (kv.value as Object).toBson(
          includeNullValues: includeNullValues,
          keyNameConverter: keyNameConverter,
        );
      }
      return newMap;
    } else if (this is Enum) {
      return (this as Enum).enumToString();
    }
    final instanceMirror = reflect(this);

    final declarations = instanceMirror.includeParentDeclarationsIfNecessary();

    final Map<String, dynamic> json = {};
    JsonKeyNameConverter? classLevelKeyNameConverter =
        instanceMirror.type.tryGetKeyNameConverter();
    if (classLevelKeyNameConverter != null && keyNameConverter != null) {
      /// if you pass a keyNameConverter, it will override the existing annotation of the same type
      classLevelKeyNameConverter = null;
    }
    keyNameConverter ??= classLevelKeyNameConverter;
    for (var kv in declarations.entries) {
      if (kv.value is VariableMirror) {
        final variableMirror = kv.value as VariableMirror;
        Object? rawValue = instanceMirror
            .getField(
              variableMirror.simpleName,
            )
            .reflectee;
        final isJsonIncluded = variableMirror.isJsonIncluded;
        if (variableMirror.isPrivate) {
          if (!isJsonIncluded) {
            continue;
          }
        } else {
          if (variableMirror.isJsonIgnored) {
            continue;
          }
        }
        if (!includeNullValues && rawValue == null) {
          continue;
        }
        final alternativeName = variableMirror.alternativeName;

        final valueConverters =
            variableMirror.getAnnotationsOfType<JsonValueConverter>();
        for (final converter in valueConverters) {
          if (converter is MongoIdConverter) {
            /// it's a unique case where we don't need it to be converted into a
            /// simpler value but instead into a mongo's ObjectId
            /// so we use `ConvertDirection.fromJson` instead, to reverse the possible conversion
            rawValue = converter.convert(
              rawValue,
              ConvertDirection.fromJson,
            );
          } else {
            rawValue = converter.convert(
              rawValue,
              ConvertDirection.toJson,
            );
          }
        }

        Object? value;
        if (rawValue.runtimeType.isPrimitive) {
          value = rawValue;
        } else if (rawValue is List) {
          value = rawValue.map(
            (Object? e) {
              return e?.toBson(
                includeNullValues: includeNullValues,
              );
            },
          ).toList();
        } else if (rawValue is Enum) {
          value = rawValue.enumToString();
        } else if (rawValue is DateTime) {
          /// Mongo can accept regular DateTime
          value = rawValue;
        } else if (rawValue is Map) {
          value = rawValue.map(
            (key, Object? value) => MapEntry(
              key,
              value?.toBson(
                includeNullValues: includeNullValues,
              ),
            ),
          );
        } else {
          value = rawValue?.toBson();
        }
        final variableName = alternativeName ??
            variableMirror.tryConvertVariableNameViaAnnotation(
              variableName: variableMirror.name,
              keyNameConverter: keyNameConverter,
            );

        json[variableName] = value;
      }
    }
    return json;
  }
}
