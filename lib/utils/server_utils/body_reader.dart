import 'dart:async';
import 'dart:io';

import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
import 'package:dart_net_core_api/utils/server_utils/any_logger.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';

import 'codec_utils.dart';
import 'form_entry.dart';

Future<Object?> tryReadRequestBody(
  HttpRequest request,
  String traceId,
  int maxUploadFileSize,
) async {
  try {
    final bodyData = BodyData(
      request: request,
      maxSize: maxUploadFileSize,
    );
    return await bodyData.decode();
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      message: 'Could not read request body ${e.toString()}',
      traceId: traceId,
    );
  }
}

class BodyData {
  BodyData({
    required this.request,
    required this.maxSize,
  }) {
    _originalByteStream = request;
  }

  late final Stream<List<int>> _originalByteStream;

  final int maxSize;

  final HttpRequest request;

  bool get _hasContent {
    return _hasContentLength || request.headers.chunkedTransferEncoding;
  }

  bool get _hasContentLength {
    return request.headers.contentLength > 0 || request.contentLength > 0;
  }

  Stream<List<int>> get bytes {
    if (_hasContentLength) {
      if (request.headers.contentLength > maxSize) {
        throw ApiException(
          message: 'Entity to large',
          traceId: null,
          statusCode: HttpStatus.requestEntityTooLarge,
        );
      }

      return _originalByteStream;
    }

    if (_bufferStreamController == null) {
      _bufferStreamController = StreamController<List<int>>(sync: true);

      _originalByteStream.listen(
        (chunk) {
          _bytesRead += chunk.length;
          if (_bytesRead > maxSize) {
            _bufferStreamController!.close();
            throw ApiException(
              message: 'Request entity too large',
            );
          }

          _bufferStreamController!.add(chunk);
        },
        onDone: () {
          _bufferStreamController!.close();
        },
        onError: (Object e, StackTrace st) {
          if (!_bufferStreamController!.isClosed) {
            _bufferStreamController!.addError(e, st);
            _bufferStreamController!.close();
          }
        },
        cancelOnError: true,
      );
    }

    return _bufferStreamController!.stream;
  }

  ContentType? get contentType {
    return request.headers.contentType;
  }

  bool get isEmpty {
    return !_hasContent;
  }

  bool get isFormData {
    return contentType!.subType == 'form-data';
  }

  bool get isUrlEncodedFormData {
    return contentType!.subType == 'x-www-form-urlencoded';
  }

  Future<List<FormEntry>> _toFormDataFiles(
    List<int> bytes,
  ) async {
    try {
      final mimeParts = await _getFormDataAsMimeMultipart(bytes);
      final List<FormEntry> files = [];
      for (var p in mimeParts) {
        final bytes = await p.toList();
        final file = FormEntry.fromContentDispositionAndBytes(
          listOfByteLists: bytes,
          contentDisposition: p.headers['content-disposition'] ?? '',
          contentType: p.headers['content-type'] ?? '',
        );
        if (file.isString) {
          files.add(
            FormEntry.fromRawData(
              value: file.readAsString(),
              name: file.name,
            ),
          );
        } else if (file.isSingleFile) {
          files.add(
            FileFormEntry(
              name: file.name,
              value: file.bytes.first,
              realFileName: file.realFileName,
            ),
          );
        } else {
          /// The base form entry may contain a few files
          files.add(file);
        }
      }
      return files.where((e) => e.isValid).toList();
    } catch (e, s) {
      logGlobal(
        level: Level.SEVERE,
        message: e.toString(),
        stackTrace: s,
      );
    }
    return [];
  }

  Future<List<MimeMultipart>> _getFormDataAsMimeMultipart(
    List<int> bytes,
  ) async {
    final boundary = request.headers.contentType?.parameters['boundary'] ?? '';
    final bodyStream = Stream.fromIterable([bytes]);
    final transformer = MimeMultipartTransformer(boundary);
    return transformer.bind(bodyStream).toList();
  }

  bool retainOriginalBytes = false;

  bool get hasBeenDecoded {
    return _decodedData != null || isEmpty;
  }

  Type get decodedType {
    if (!hasBeenDecoded) {
      throw StateError(
        "Invalid body decoding. Must decode data prior to calling 'decodedType'.",
      );
    }

    return _decodedData.runtimeType;
  }

  List<int>? get originalBytes {
    if (retainOriginalBytes == false) {
      throw StateError(
        "'originalBytes' were not retained. Set 'retainOriginalBytes' to true prior to decoding.",
      );
    }
    return _bytes;
  }

  Object? _decodedData;
  List<int>? _bytes;

  Future<Object?> decode() async {
    if (hasBeenDecoded) {
      return _decodedData;
    }

    final codec = CodecUtils.instance.codecForContentType(
      contentType,
    );
    final originalBytes = await _readBytes(bytes);

    if (retainOriginalBytes) {
      _bytes = originalBytes;
    }

    try {
      if (codec == null) {
        if (isFormData) {
          return _toFormDataFiles(originalBytes);
        }
        _decodedData = originalBytes;
        return _decodedData;
      }
      _decodedData = codec.decoder.convert(originalBytes);
      if (isUrlEncodedFormData) {
        if (_decodedData is Map) {
          final entries = (_decodedData as Map)
              .entries
              .map((e) {
                final name = e.key;
                final rawValues = e.value as List;
                if (rawValues.length == 1) {
                  return FormEntry.fromRawData(
                    name: name,
                    value: rawValues.first,
                  );
                }
                return null;
              })
              .whereType<FormEntry>()
              .toList();

          return entries;
        }
      }
    } catch (e) {
      throw 'Entity could not be decoded';
    }

    return _decodedData;
  }

  Future<List<int>> _readBytes(Stream<List<int>> stream) async {
    return (await stream.toList()).expand((e) => e).toList();
  }

  // ignore: close_sinks
  StreamController<List<int>>? _bufferStreamController;
  int _bytesRead = 0;
}
