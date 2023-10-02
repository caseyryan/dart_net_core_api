part of 'simple_type_reflector.dart';

class JsonObjectReflector {
  final Map _json = {};

  JsonObjectReflector({
    required Object object,
    KeyNameConverter? keyNameConverter,
  }) {
    final typeReflector = JsonTypeReflector(object.runtimeType);
    final instanceMirror = reflect(object);
    for (Variable variable in typeReflector._variables) {
      final fieldInstanceMirror = instanceMirror.getField(variable.symbolicName);

      final ClassMirror classMirror = fieldInstanceMirror.type;
      final value = fieldInstanceMirror.reflectee;
      if (variable.isJsonIgnored) {
        continue;
      }
      var key = variable.jsonName;
      if (!variable.hasOverriddenName && keyNameConverter != null) {
        key = keyNameConverter.convert(key);
      }
      if (classMirror.isPrimitiveType) {
        _json[key] = value;
      } else {
        if (value is List) {
          _json[key] = value
              .map(
                (Object? e) => e?.toJson(),
              )
              .toList();
        } else if (value is Map) {
          _json[key] = value.map(
            (key, Object? value) {
              return MapEntry(
                key,
                value?.toJson(),
              );
            },
          );
        } else {
          _json[key] = (value as Object?)?.toJson();
        }
      }
    }
  }

  Map toJson() {
    return _json;
  }
}
