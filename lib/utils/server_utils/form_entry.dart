import 'dart:convert';

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

class FormEntry {
  const FormEntry({
    required this.name,
    required this.realFileName,
     this.contentType = '',
     this.bytes = const [],
  });

  final String name;
  final String realFileName;
  final String contentType;
  final List<List<int>> bytes;

  bool get isString {
    return realFileName.isNotEmpty != true && name.isNotEmpty;
  }

  bool get isVideo {
    return contentType.contains('video');
  }

  bool get isImage {
    return contentType.contains('image');
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
      /// TODO: add logger here
    }
    return FormEntry(
      name: '',
      realFileName: '',
      contentType: '',
      bytes: [],
    );
  }
}
