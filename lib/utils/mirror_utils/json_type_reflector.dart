part of 'simple_type_reflector.dart';

/// This reflector is used for json serialization purposes only
/// Only public variables can be serialized / deserialized by default
///
class JsonTypeReflector extends SimpleTypeReflector {
  JsonTypeReflector(super.fromType) {
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
          variables.add(
            Variable(
              mirror: varMirror,
              symbolicName: kv.key,
            ),
          );
        }
      }
    }
    print(variables);
  }

  final List<Variable> variables = [];
}

class Variable {
  final VariableMirror mirror;
  final Symbol symbolicName;

  String? _name;
  late Type _reflectedType;
  late String _reflectedTypeName;
  late List<JsonTypeReflector> typeArguments;
  bool _isGeneric = false;

  Variable({
    required this.mirror,
    required this.symbolicName,
  }) {
    _reflectedType = mirror.type.reflectedType;
    _reflectedTypeName = _reflectedType.toString();
    typeArguments = mirror.type.typeArguments
        .map(
          (e) => JsonTypeReflector(e.reflectedType),
        )
        .toList();
    _isGeneric = mirror.type.typeArguments.isNotEmpty;
  }

  bool get isGeneric {
    return _isGeneric;
  }

  String get name {
    _name ??= symbolicName.toName();
    return _name!;
  }

  bool get isList {
    return _reflectedType is Iterable;
  }

  bool get isPrimitiveType {
    switch (_reflectedType) {
      case String:
      case double:
      case num:
      case int:
      case bool:
        return true;
    }
    return false;
  }

  @override
  String toString() {
    return '[Variable: name: $name, type: ${mirror.type.reflectedType}, isPrimitive: $isPrimitiveType, isGeneric: $isGeneric]';
  }
}
