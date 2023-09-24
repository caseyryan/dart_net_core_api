import 'package:collection/collection.dart';

import 'endpoint_path_parser.dart';

/// Must be used with [EndpointPathParser.tryMatchPath]
/// to fill the path variables with missing values
class IncomingPathParser {
  final String fullUrl;

  /// all the incoming query parameters
  late final List<QueryArgument> arguments;
  late final String path;
  late final bool isValid;

  /// It is required here only to calculate the number of segments
  EndpointPathParser? _endpointPathParser;
  String? _endpointPath;

  /// These variables will be extracted after calling
  /// [EndpointPathParser.tryMatchPath]
  /// to match a corresponding endpoint
  List<QueryArgument> _positionalPathVariables = [];
  List<QueryArgument> get positionalPathVariables => _positionalPathVariables;

  QueryArgument? tryFindQueryArgument({
    required String argumentName,
  }) {
    return arguments.firstWhereOrNull((a) => a.name == argumentName);
  }


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
      arguments = parsedParams.queryParameters.entries.mapIndexed((index, kv) {
        return QueryArgument(
          name: kv.key,
          value: kv.value,
        );
      }).toList();
      /// Very important line! Do not move or remove
      _endpointPathParser = EndpointPathParser(
        path,
      );
    }
  }

  Map toMap() {
    return {
      'fullUrl': fullUrl,
      'path': path,
      'params': arguments.map((e) => e.toMap()).toList(),
      'matchedEndpointPath': _endpointPath,
    };
  }

  void updatePositionalVariables({
    required List<QueryArgument> value,
    required String endpointPath,
  }) {
    _positionalPathVariables = value;
    _endpointPath = endpointPath;
    arguments.addAll(value);
  }

  int get totalSegments {
    return _endpointPathParser?.totalSegments ?? 0;
  }
}

class QueryArgument {
  const QueryArgument({
    required this.name,
    required this.value,
  });

  final String name;
  final String value;

  Map toMap() {
    return {
      'name': name,
      'value': value,
    };
  }
}
