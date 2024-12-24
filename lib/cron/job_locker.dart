import 'dart:io';

import 'package:reflect_buddy/reflect_buddy.dart';

class JobLocker {
  final Directory tempFilesRoot;
  final String jobName;

  int _counter = 0;
  get counter => _counter;

  JobLocker(
    this.tempFilesRoot,
    this.jobName,
  ) {
    releaseLock();
    _removeCounterFile();
  }

  void _removeCounterFile() {
    final counterFile = File(_counterFilePath);
    if (counterFile.existsSync()) {
      counterFile.deleteSync(recursive: true);
    }
  }

  String get _lockFilePath {
    return '${tempFilesRoot.path}/.${jobName.camelToSnake()}.lock';
  }

  String get _counterFilePath {
    return '${tempFilesRoot.path}/.${jobName.camelToSnake()}_run.counter';
  }

  bool obtainLock() {
    try {
      File(_lockFilePath).createSync(
        recursive: true,
        exclusive: true,
      );
      final counterFile = File(_counterFilePath);
      if (!counterFile.existsSync()) {
        counterFile.createSync(recursive: true);
      }
      if (counterFile.existsSync()) {
        _counter = int.tryParse(counterFile.readAsStringSync()) ?? 1;
        counterFile.writeAsStringSync(
          (_counter + 1).toString(),
          flush: true,
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  void releaseLock() {
    File(_lockFilePath).delete(recursive: true);
  }
}
