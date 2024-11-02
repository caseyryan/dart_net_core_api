import 'dart:io';

import 'package:mime/mime.dart' as mime;

extension DirectoryExtension on Directory {
  File? toFile(String? fileName) {
    if (fileName?.isNotEmpty != true) {
      return null;
    }
    if (!existsSync()) {
      return null;
    }
    return File('$path/$fileName');
  }
}

extension FileExtension on File {
  String? get mimeType {
    return mime.lookupMimeType(path);
  }

  String get name {
    return path.split('/').last;
  }

  /// Writes or re-writes a file even if it exists
  Future<bool> forceWriteBytes(
    List<int> bytes,
  ) async {
    try {
      if (!await exists()) {
        await create(recursive: true);
      }
      await writeAsBytes(
        bytes,
        mode: FileMode.write,
        flush: true,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}
