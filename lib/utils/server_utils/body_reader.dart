import 'dart:async';
import 'dart:io';

import 'package:dart_net_core_api/exceptions/base_exception.dart';
import 'package:mime/mime.dart';

import 'codec.dart';
import 'form_entry.dart';

Future<Object?> tryReadRequestBody(
  HttpRequest request,
  String traceId,
) async {
  try {
    final bodyData = _BodyData(
      request: request,
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

class _BodyData {
  _BodyData({
    required this.request,
  }) {
    _originalByteStream = request;
  }

  late final Stream<List<int>> _originalByteStream;

  static int maxSize = 1024 * 1024 * 10;

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
    return contentType != null &&
        (contentType!.subType == 'x-www-form-urlencoded' ||
            contentType!.subType == 'form-data');
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
            StringFormEntry(
              name: file.name,
              value: file.readAsString(),
            ),
          );
        } else {
          files.add(file);
        }
      }
      print(files);
      return files.where((e) => e.isValid).toList();
    } catch (e) {
      /// TODO: add logger here
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

    final codec = CodecRegistry.instance.codecForContentType(
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
