import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_net_core_api/cron/job_locker.dart';
import 'package:dart_net_core_api/utils/extensions/exports.dart';
import 'package:dart_net_core_api/utils/mirror_utils/simple_type_reflector.dart';

import '../../exports.dart';

/// Add this service to the list of services if you need to generate the API documentation
/// you can also extend this class to process the documentation in your own way

class ApiDocumentationService extends Service {
  ApiDocumentationService({
    required this.describeTypes,
  });

  /// [describeTypes] if true, all types will be described
  /// and displayed in the documentation
  final bool describeTypes;

  List<Type> _controllerTypes = [];
  String? _serverBaseApiPath;

  JobLocker? _jobLocker;

  Future<Map> tryGetDocumentationForCurrentEnvironment() async {
    // if (_jobLocker!.obtainLock()) {
    final staticFileDir = getConfig<Config>()?.staticFileDirectory;
    if (staticFileDir?.existsSync() != true) {
      return {};
    }
    final jsonFileName = 'docs/api.$environment.json';
    final jsonFile = File('${staticFileDir!.path}/$jsonFileName');
    if (jsonFile.existsSync()) {
      final jsonString = await jsonFile.readAsString();
      if (jsonString.startsWith('{')) {
        return jsonDecode(jsonString);
      }
    }
    // }
    return {};
  }

  void setControllerTypes(
    List<Type> controllerTypes,
    String? serverBaseApiPath,
  ) {
    _controllerTypes = controllerTypes;
    _serverBaseApiPath = serverBaseApiPath;
  }

  /// Actual documentation generation
  Future _generateDocumentation() async {
    _jobLocker ??= JobLocker(
      getConfig<Config>()!.tempFilesRoot!,
      runtimeType.toString(),
    );

    /// Only one process should generate the documentation at a time
    if (_jobLocker!.obtainLock()) {
      final staticFileDir = getConfig<Config>()?.staticFileDirectory;
      if (staticFileDir?.existsSync() != true) {
        _jobLocker?.releaseLock();
        return;
      }
      final controllers = <Map>[];
      final allResponseModels = <Object>{};
      for (Type controllerType in _controllerTypes) {
        final simpleTypeReflector = SimpleTypeReflector(controllerType);
        final docContainer = simpleTypeReflector.documentationContainer;
        if (docContainer != null) {
          final map = docContainer.toApiDocumentation(
            _serverBaseApiPath!,
            null,
            (models) {
              allResponseModels.addAll(models);
            },
          );
          controllers.add(map);
        }
      }
      final maps = {};
      if (describeTypes) {
        for (var model in allResponseModels) {
          if (model is Type) {
            maps.addAll(model.documentType());
          }
        }
        print(maps);
      }
      final data = <String, Object?>{
        'controllers': controllers,
      };
      if (describeTypes) {
        data['types'] = maps.values.toList();
      }
      final formattedJson = data.toFormattedJson();

      final jsonFileName = 'docs/api.$environment.json';
      final jsonFile = File('${staticFileDir!.path}/$jsonFileName');
      await jsonFile.forceWriteBytes(
        utf8.encode(formattedJson),
      );
      await Future.delayed(const Duration(seconds: 5));
      _jobLocker?.releaseLock();
    } else {
      print('DOC FILE LOCKED');
    }
  }

  @override
  FutureOr dispose() {
    throw 'This service must not be added as a singleton';
  }

  @override
  FutureOr onReady() async {
    _generateDocumentation();
  }
}
