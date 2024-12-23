import 'dart:mirrors';

import 'package:dart_core_orm/dart_core_orm.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

extension ClassMirrorExtensions on ClassMirror {
  /// [objectType] is the type of the object that is being queried
  /// for example Car, User etc. The type of your model
  List<FieldDescription> getFieldsDescriptions(Type objectType) {
    final json = objectType.fromJson(
      {},
      useValidators: false,
    );
    final convertedKeys = <String, String>{};
    json!.toJson(
      includeNullValues: true,
      onKeyConversion: (
        ConvertedKey keyConversionResult,
      ) {
        convertedKeys[keyConversionResult.oldKey] = keyConversionResult.newKey;
      },
    );
    Map<Symbol, DeclarationMirror> tempDeclarations = {};

    /// Parent declarations will be included if the class
    /// has the [JsonIncludeParentFields] annotation from reflect_buddy
    /// this may come in handy when you want all base models have the same functionality
    final possibleParentDeclarations = includeParentDeclarationsIfNecessary();
    tempDeclarations.addAll(possibleParentDeclarations);
    tempDeclarations.addAll(declarations);

    final fields = tempDeclarations.entries
        .where(
          (e) =>
              e.value is VariableMirror &&
              !(e.value as VariableMirror).isPrivate &&
              !(e.value as VariableMirror).isConst,
        )
        .toList();
    final fieldDescriptions = <FieldDescription>[];
    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      if (field.value is VariableMirror) {
        var name = field.key.toName();
        name = convertedKeys[name] ?? name;
        final fieldDartType =
            (field.value as VariableMirror).type.reflectedType;
        fieldDescriptions.add(
          getFieldDescription(
            fieldName: name,
            fieldDartType: fieldDartType,
            metadata: field.value.metadata,
          ),
        );
      }
    }
    return fieldDescriptions;
  }
}
