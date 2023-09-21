import 'package:collection/collection.dart';

import 'endpoint_path_parser.dart';

/// Must be used with [EndpointPathParser.tryMatchPath]
/// to fill the path variables with missing values
class IncomingPathParser {
  final String fullUrl;

  /// all the parameters that go after
  late final List<PathVariable> namedParams;
  late final String path;
  late final bool isValid;

  EndpointPathParser? _endpointPathParser;
  String? _endpointPath;

  /// These variables will be extracted after calling
  /// [EndpointPathParser.tryMatchPath]
  /// to match a corresponding endpoint
  List<PathVariable> _positionalPathVariables = [];
  List<PathVariable> get positionalPathVariables => _positionalPathVariables;

  List<QuerySegment> get querySegments {
    return _endpointPathParser?.querySegments ?? [];
  }

  IncomingPathParser(
    this.fullUrl,
  ) {
    final parsedParams = Uri.tryParse(fullUrl);
    if (parsedParams == null) {
      isValid = false;
    } else {
      isValid = true;
      path = parsedParams.path;
      namedParams = parsedParams.queryParameters.entries.mapIndexed((index, kv) {
        return PathVariable(
          name: kv.key,
          value: kv.value,
          isRequired: false,
          index: index,
        );
      }).toList();
      _endpointPathParser = EndpointPathParser(
        path,
      );
    }
  }

  Map toMap() {
    return {
      'positionalParameters': positionalPathVariables.map((e) => e.toMap()).toList(),
      'namedParameters': namedParams.map((e) => e.toMap()).toList(),
      'fullUrl': fullUrl,
      'path': path,
      'matchedEndpointPath': _endpointPath,
    };
  }

  void updatePositionalVariables({
    required List<PathVariable> value,
    required String endpointPath,
  }) {
    _positionalPathVariables = value;
    _endpointPath = endpointPath;
  }

  int get totalSegments {
    return _endpointPathParser?.totalSegments ?? 0;
  }
}

class PathVariable {
  const PathVariable({
    required this.name,
    required this.value,
    required this.isRequired,
    required this.index,
  });

  final String name;
  final dynamic value;
  final bool isRequired;
  final int index;

  Map toMap() {
    return {
      'name': name,
      'value': value,
      'isRequired': isRequired,
      'index': index,
    };
  }
}
