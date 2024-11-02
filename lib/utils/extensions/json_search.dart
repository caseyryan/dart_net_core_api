
import 'package:collection/collection.dart';

final _depthRegex = RegExp(r'(?<=\()(\d+)(?=\))');

class SearchValueContainer {
  Object? value;
  String key;
  SearchValueContainer({
    this.value,
    required this.key,
  });
}

class _DepthWrapper {
  int? depth;
  SearchValueContainer? found;
  _DepthWrapper({
    this.depth,
    this.found,
  });
}

extension JsonStringExtension on String {
  bool get hasRegexPattern {
    return startsWith('/') && endsWith('/');
  }

  RegExp? toRegExp() {
    if (!hasRegexPattern) {
      return null;
    }
    final pattern = replaceFirst('/', '').substring(0, length - 2);
    return RegExp(pattern);
  }
}

extension JsonListExtension on List {
  List<_DepthWrapper> _searchForKey({
    required String key,
    int depth = 0,
  }) {
    List<_DepthWrapper> temp = [];
    for (var value in this) {
      if (value is Map) {
        final map = value;
        temp.addAll(
          map._searchForKey(
            key: key,
            depth: depth + 1,
          ),
        );
      } else if (value is List) {
        final list = value;
        temp.addAll(
          list._searchForKey(
            key: key,
            depth: depth + 1,
          ),
        );
      }
    }
    return temp;
  }

  String? _getFirstNonEmpty(int startIndex) {
    if (startIndex >= length) {
      return null;
    }
    for (var i = startIndex; i < length; i++) {
      final value = this[i];
      if (value is String) {
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }
}

Map _regExps = <String, RegExp>{};

RegExp _getOrCreateRegexp(String key) {
  if (_regExps.containsKey(key)) {
    return _regExps[key];
  }
  _regExps[key] = key.toRegExp();
  return _regExps[key];
}

extension JsonMapExtension on Map {
  List<_DepthWrapper> _searchForKey({
    required String key,
    int depth = 0,
  }) {
    bool isRegexPattern = key.hasRegexPattern;
    List<_DepthWrapper> temp = [];
    Object? curValue;

    if (!isRegexPattern) {
      curValue = this[key];
      curValue = SearchValueContainer(
        key: key,
        value: curValue,
      );
    } else {
      final regExp = _getOrCreateRegexp(key);
      final kv = entries.firstWhereOrNull((kv) => regExp.hasMatch(kv.key));
      if (kv != null) {
        curValue = SearchValueContainer(
          key: kv.key,
          value: kv.value,
        );
      }
    }
    if (curValue != null && curValue is SearchValueContainer) {
      temp.add(
        _DepthWrapper(
          depth: depth,
          found: curValue,
        ),
      );
    }
    for (var v in values) {
      if (v is Map) {
        final map = v;
        temp.addAll(
          map._searchForKey(
            key: key,
            depth: depth + 1,
          ),
        );
      } else if (v is List) {
        final list = v;
        temp.addAll(
          list._searchForKey(
            key: key,
            depth: depth + 1,
          ),
        );
      }
    }
    return temp;
  }
  /// [path] it might be a list of strings like
  /// ["person", "name"] or a dot-separated string path like
  /// person.name. In both cases it will work the same
  /// it will work for a map that contains a key called `person`, and
  /// the search for an object with a key `name` inside.
  /// It can also search in [List]s.
  /// The [path] also supports "unknown depth" search, e.g
  /// `find('..person')` will search for a key `person` at any depth and
  /// return the the list of found values. If you know exactly at what depth your
  /// target value is, just pass it in braces after the key name e.g.
  /// `find('..person(3)')` will return objects that are at a depth of 3 (starting with 0).
  /// Both approaches also support [RegExp] patterns. If you want to
  /// search something by a [RegExp] pass a pattern like this
  /// `find('../[\d]{3}/')` it will return all objects whose keys match a 3-digit pattern
  /// or like this `find('../[\d]{3}/(3)')` if will return all objects
  /// whose keys match a 3-digit pattern and are placed at a depth of 3
  T? find<T>(Object path) {
    final result = _find(path);
    if (T is List<String>) {
      return result.map((e) => e.value?.toString()).toList() as T?;
    }
    else if (T is List<SearchValueContainer>) {
      return result as T?;
    }
    else if (result.isNotEmpty) {
      return result.first.value as T?;
    }

    return null;
  }

  
  List<SearchValueContainer> _find(Object path) {
    List<String> keys = [];
    if (path is List) {
      keys = path as List<String>;
    } else if (path is String) {
      keys = path.trim().split('.').toList();
    }

    if (keys.isEmpty) {
      return const [];
    }
    final currentKey = keys.first;

    if (currentKey == '' || currentKey == '*') {
      /// This is a special condition where you don't know the exact path

      var nextKey = keys._getFirstNonEmpty(1);
      if (nextKey == null) {
        return const [];
      }

      final depthMatch = _depthRegex.firstMatch(nextKey);
      int? maxDepth;

      /// nextKey.endsWith(')') is very important condition here
      /// because nextKey may contain a regular expression which also allows groups
      if (depthMatch != null && nextKey.endsWith(')')) {
        maxDepth = int.tryParse(depthMatch.group(0)!);
        nextKey = nextKey.substring(0, nextKey.lastIndexOf('('));
      }

      final temp = <_DepthWrapper>[];
      for (var kv in entries) {
        if (kv.value is Map) {
          final map = kv.value as Map;
          final value = map._searchForKey(
            key: nextKey,
          );
          if (value.isNotEmpty) {
            temp.addAll(value);
          }
        } else if (kv.value is List) {
          final list = kv.value as List;
          temp.addAll(
            list._searchForKey(
              key: nextKey,
            ),
          );
        } else {
          if (kv.key == nextKey) {
            temp.add(
              _DepthWrapper(
                depth: 0,
                found: SearchValueContainer(
                  key: nextKey,
                  value: kv.value,
                ),
              ),
            );
          }
        }
      }
      if (maxDepth == null) {
        return temp.where((e) => e.found != null).map((e) => e.found!).toList();
      } else {
        final byDepth = temp.where((e) => e.depth == maxDepth).toList();
        return byDepth.where((e) => e.found != null).map((e) => e.found!).toList();
      }
    } else {
      bool isRegexPattern = currentKey.hasRegexPattern;

      SearchValueContainer? data;

      if (!isRegexPattern) {
        data = SearchValueContainer(
          key: currentKey,
          value: this[currentKey],
        );
      } else {
        final regExp = _getOrCreateRegexp(currentKey);
        final kv = entries.firstWhereOrNull(
          (kv) => regExp.hasMatch(kv.key),
        );
        if (kv != null) {
          data = SearchValueContainer(
            key: kv.key,
            value: kv.value,
          );
        }
      }
      if (data == null) {
        return const [];
      }

      if (data.value == null) {
        return const [];
      }
      if (keys.length == 1) {
        return [data];
      } else {
        keys.removeAt(0);
        if (data.value is Map) {
          return (data.value as Map).find(keys);
        } else if (data.value is List) {
          final list = data.value as List;
          final tempList = <SearchValueContainer>[];
          for (var value in list) {
            if (value is Map) {
              tempList.addAll(value.find(keys));
            } else if (value is SearchValueContainer && value.value is Map) {
              final map = value.value as Map;
              tempList.addAll(map.find(keys));
            }
          }
          return tempList;
        }
      }
    }

    return const [];
  }
}
