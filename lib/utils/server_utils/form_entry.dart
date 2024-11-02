import 'dart:convert';
import 'dart:math';

import 'package:dart_net_core_api/utils/extensions/exports.dart';
import 'package:mime/mime.dart' as mime;
import 'package:path/path.dart';

final _random = Random();

class StringFormEntry extends FormEntry {
  const StringFormEntry({
    required super.name,
    required this.value,
  }) : super(
          realFileName: '',
          bytes: const [],
        );
  final String value;

  @override
  bool get isValid {
    return true;
  }
}

class BoolFormEntry extends FormEntry {
  const BoolFormEntry({
    required super.name,
    required this.value,
  }) : super(
          realFileName: '',
          bytes: const [],
        );
  final bool value;

  @override
  bool get isValid {
    return true;
  }
}

class IntFormEntry extends FormEntry {
  const IntFormEntry({
    required super.name,
    required this.value,
  }) : super(
          realFileName: '',
          bytes: const [],
        );
  final int value;

  @override
  bool get isValid {
    return true;
  }
}

class DoubleFormEntry extends FormEntry {
  const DoubleFormEntry({
    required super.name,
    required this.value,
  }) : super(
          realFileName: '',
          bytes: const [],
        );
  final double value;

  @override
  bool get isValid {
    return true;
  }
}

class FileFormEntry extends FormEntry {
  FileFormEntry({
    required super.name,
    required super.realFileName,
    required this.value,
  }) : super(
          bytes: const [],
        );
  final List<int> value;

  String? _randomFileName;

  @override
  bool get isVideo {
    if (mimeType?.isNotEmpty != true) {
      return super.isVideo;
    }
    return mimeType!.startsWith('video/') == true;
  }

  @override
  bool get isImage {
    if (mimeType?.isNotEmpty != true) {
      return super.isImage;
    }
    return mimeType!.startsWith('image/') == true;
  }

  @override
  bool get isAudio {
    if (mimeType?.isNotEmpty != true) {
      return super.isAudio;
    }
    return mimeType!.startsWith('audio/') == true;
  }

  /// The random name is used to write file to a disk
  /// trying to minimize a potential name conflict with the existing files
  String toRandomFileName({
    String subDirectory = '',
  }) {
    if (_randomFileName != null) {
      return _randomFileName!;
    }
    final mimeType = this.mimeType;
    if (realFileName.isNotEmpty == true && mimeType != null) {
      var ext = extension(realFileName);
      if (ext.isEmpty) {
        ext = mime.extensionFromMime(mimeType);
      }
      ext = ext.replaceAll('.', '');
      _randomFileName = '${'$realFileName${_random.nextDouble()}'.toMd5()}.$ext';
    } else {
      _randomFileName = name.toMd5();
    }
    if (subDirectory.isNotEmpty) {
      _randomFileName = '$subDirectory/$_randomFileName';
    }
    return _randomFileName!;
  }

  String? get mimeType {
    return mime.lookupMimeType(
      realFileName,
      headerBytes: value,
    );
  }

  @override
  bool get isValid {
    return true;
  }
}

class FormEntry {
  const FormEntry({
    required this.name,
    required this.realFileName,
    this.contentType = '',
    this.bytes = const [],
  });

  factory FormEntry.fromRawData({
    required Object? value,
    required String name,
  }) {
    final convertedValue = _tryConvertPrimitive(value);
    switch (convertedValue.runtimeType) {
      case String:
        return StringFormEntry(
          name: name,
          value: convertedValue as String,
        );
      case double:
        return DoubleFormEntry(
          name: name,
          value: convertedValue as double,
        );
      case int:
        return IntFormEntry(
          name: name,
          value: convertedValue as int,
        );
      case bool:
        return BoolFormEntry(
          name: name,
          value: convertedValue as bool,
        );
    }

    return StringFormEntry(
      name: name,
      value: convertedValue.toString(),
    );
  }

  final String name;
  final String realFileName;
  final String contentType;
  final List<List<int>> bytes;

  bool get isString {
    return realFileName.isNotEmpty != true && name.isNotEmpty;
  }

  bool get isSingleFile {
    return bytes.length == 1;
  }

  bool get isVideo {
    return contentType.contains('video');
  }

  bool get isImage {
    return contentType.startsWith('image/');
  }

  bool get isAudio {
    return contentType.startsWith('audio/');
  }

  String readAsString() {
    if (bytes.isNotEmpty) {
      return utf8.decode(bytes.first);
    }
    return '';
  }

  List<int> getFileBytes() {
    if (bytes.isNotEmpty) {
      return bytes.first;
    }
    return [];
  }

  bool get isValid {
    return bytes.isNotEmpty;
  }

  factory FormEntry.fromContentDispositionAndBytes({
    required String contentDisposition,
    required String contentType,
    required List<List<int>> listOfByteLists,
  }) {
    try {
      String? fileName;
      String? formFieldName;
      final str = contentDisposition;
      final presplit = str.split(';');
      final quotesRegex = RegExp(r'"[^"]*"');

      for (var part in presplit) {
        if (part.contains('=')) {
          final s = part.split('=');
          if (s.length > 1) {
            final first = s.first.trim().toLowerCase();
            final second = s[1].trim().toLowerCase();
            if (!second.contains('"')) {
              continue;
            }
            final quotedMatch = quotesRegex.firstMatch(
              second,
            );
            if (quotedMatch == null) {
              continue;
            }
            final quoteStr = second
                .substring(
                  quotedMatch.start,
                  quotedMatch.end,
                )
                .replaceAll('"', '');
            if (first.contains('filename')) {
              fileName = quoteStr;
            } else if (first.contains('name')) {
              formFieldName = quoteStr;
            }
          }
        }
      }
      return FormEntry(
        name: formFieldName ?? '',
        realFileName: fileName ?? '',
        contentType: contentType,
        bytes: listOfByteLists,
      );
    } catch (e) {
      print('FormEntry -> $e');
    }
    return FormEntry(
      name: '',
      realFileName: '',
      contentType: '',
      bytes: [],
    );
  }
}

RegExp _intRegExp = RegExp(r'(-?)[0-9]+$');
RegExp _doubleRegExp = RegExp(r'(-?)(0|([1-9][0-9]*))(\.[0-9]+)?$');

Object? _tryConvertPrimitive(Object? value) {
  if (value is String) {
    if (value.length > 3 && value.length <= 5) {
      final lowerValue = value.toLowerCase();
      if (lowerValue == 'true' || lowerValue == 'false') {
        return bool.fromEnvironment(lowerValue);
      }
    }
    if (_intRegExp.stringMatch(value)?.length == value.length) {
      return int.tryParse(value);
    }
    if (_doubleRegExp.stringMatch(value)?.length == value.length) {
      return double.tryParse(value);
    }
  }
  return value;
}
