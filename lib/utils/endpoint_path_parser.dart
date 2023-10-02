import 'package:dart_net_core_api/utils/extensions.dart';

import 'incoming_path_parser.dart';

/// Prepares endpoints for matching when called
class EndpointPathParser {
  final List<QuerySegment> _querySegments = [];
  List<QuerySegment> get querySegments => _querySegments;
  late final String originalPath;

  static final RegExp _optionalVarRegexp = RegExp(r'(?<={):[a-zA-Z0-9_-]+(?=})');
  static final RegExp _positionalVarRegexp = RegExp(r'(?<={)[a-zA-Z0-9_-]+(?=})');

  /// matches all possible segments including the variable
  final RegExp _pathSegmentsRegExp = RegExp(r'(?<=\/)[:{}a-zA-Z0-9_-]+(?=\/)*');

  int _numRequiredSegments = 0;
  int get numRequiredSegments => _numRequiredSegments;

  int get totalSegments {
    return _querySegments.length;
  }

  EndpointPathParser(String path) {
    originalPath = path;
    final segmentMatches = _pathSegmentsRegExp.allMatches(path);
    bool hasOptional = false;
    if (segmentMatches.isNotEmpty) {
      for (var m in segmentMatches) {
        var segment = path.substring(m.start, m.end);
        bool isVariable = false;
        bool isOptional = false;
        final optionalVarMatch = _optionalVarRegexp.firstMatch(
          segment,
        );
        if (optionalVarMatch != null) {
          isVariable = true;
          isOptional = true;
          hasOptional = true;

          /// start + 1 is just to remove a colon at the beginning
          segment = segment.substring(
            optionalVarMatch.start + 1,
            optionalVarMatch.end,
          );
        } else {
          _numRequiredSegments++;
          final positionalVarMatch = _positionalVarRegexp.firstMatch(
            segment,
          );
          if (positionalVarMatch != null) {
            isVariable = true;
            isOptional = false;
            segment = segment.substring(
              positionalVarMatch.start,
              positionalVarMatch.end,
            );
          } else {
            if (hasOptional) {
              throw 'Optional parameters cannot precede required ones or path segments: $originalPath';
            }
          }
        }
        _querySegments.add(
          QuerySegment(
            name: segment,
            isVariable: isVariable,
            isOptional: isOptional,
          ),
        );
      }
    }
  }

  /// returns true if an incoming path matches this
  bool tryMatchPath(IncomingPathParser value) {
    if (value.isValid) {
      if (value.totalSegments > totalSegments) {
        return false;
      }
      /// This logic is not perfect. Needs to be thought over again
      if (_numRequiredSegments > value.totalSegments ||
          totalSegments > value.querySegments.length) {
        return false;
      }

      final pathVariables = <QueryArgument>[];
      for (var i = 0; i < totalSegments; i++) {
        final mySegment = _querySegments[i];
        final incomingSegment = value.querySegments[i];
        if (!mySegment.isVariable) {
          if (mySegment.name != incomingSegment.name) {
            return false;
          }
        } else {
          pathVariables.add(
            QueryArgument(
              name: mySegment.name,
              value: incomingSegment.name,
            ),
          );
        }
      }
      value.updatePositionalVariables(
        value: pathVariables,
        endpointPath: originalPath,
      );
    }
    return true;
  }

  void printPathWithParams() {
    final temp = <Map>[];
    for (var seg in _querySegments) {
      temp.add(seg.toMap());
    }
    final value = {
      'endpoint': temp,
      'originalPath': originalPath,
      'totalSegments': totalSegments,
    }.toFormattedJson();
    print(value);
  }
}

class QuerySegment {
  const QuerySegment({
    required this.name,
    required this.isVariable,
    required this.isOptional,
  });

  final String name;
  final bool isVariable;
  final bool isOptional;

  Map toMap() {
    return {
      'name': name,
      'isVariable': isVariable,
      'isOptional': isOptional,
    };
  }
}
