import 'dart:mirrors';

T? getAnnotationInstanceOrNull<T>(List<InstanceMirror> mirrors) {
  for (var annotation in mirrors) {
    if (annotation.hasReflectee) {
      if (annotation.reflectee is T) {
        return annotation.reflectee as T;
      }
    }
  }
  return null;
}

/// finds meta annotations with a specified type or
/// a descendents of the type
List<T> getAnnotationOfType<T>(List<InstanceMirror> mirrors) {
  List<T> data = [];
  for (var annotation in mirrors) {
    if (annotation.hasReflectee) {
      if (annotation.reflectee is T) {
        data.add(annotation.reflectee);
      }
    }
  }
  return data;
}
