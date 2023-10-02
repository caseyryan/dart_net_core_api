// ignore_for_file: unnecessary_getters_setters

import 'package:dart_net_core_api/annotations/json_annotations.dart';

/// Notice that there are some JSON annotations are
/// used here. None of them is required but they help you
/// control the values before they are assigned
/// during a deserialization process. You can implement your
/// own validators extending [JsonValueValidator] class
class User {
  /// Notice this is a private field but it won't
  /// be serialized / deserialized unless it has
  /// [JsonInclude] annotation
  @JsonInclude()
  String? _id;

  /// getter / setter is here just for demo purposes
  /// to be able to set them from a demo user service
  set id(String? value) {
    _id = value;
  }

  String? get id {
    return _id;
  }

  @JsonStringValidator(
    canBeNull: false,
    regExpPattern: r'[a-zA-Z]+',
  )
  String? firstName;
  @JsonStringValidator(
    canBeNull: false,
    regExpPattern: r'[a-zA-Z]+',
  )
  String? lastName;

  /// [age] will be automatically validated
  /// according to the provided validator.
  /// If it goes beyond the specified values
  /// an error will be thrown
  @JsonIntValidator(
    minValue: 18,
    maxValue: 120,
    canBeNull: false,
  )
  int? age;

  @override
  bool operator ==(covariant User other) {
    return other._id == _id;
  }

  @override
  int get hashCode {
    return _id.hashCode;
  }
}
