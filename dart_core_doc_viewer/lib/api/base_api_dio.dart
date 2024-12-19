// ignore_for_file: unused_element
import 'dart:async';
import 'dart:io' as io;
import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

abstract class IMainInterceptor {
  late ErrorCallback? errorCallback;
  late String contentType;
  late String? bearerToken;
  late bool addAuthenticationHeaders = true;
}

abstract class IRepeatableInterceptor {
  late Function onTryAgain;
}

class ApiInitializer<T extends BaseApiDio, TDeserializer> {
  List<T> apis;
  Map<TDeserializer, Function> modelDeserializers;
  ValueChanged<Map?> errorProcessor;

  TType _findApi<TType>() {
    return apis.firstWhere((a) => a.runtimeType == TType) as TType;
  }

  ApiInitializer({
    required this.apis,
    required this.modelDeserializers,
    required this.errorProcessor,
  });
}

ApiInitializer? _initializer;
Map<String, Function> _deserializers = {};
ValueChanged<Map?>? _globalErrorProcessor;

Function? _findDeserializer<T>() {
  final typeKey = T.toString().replaceAll('?', '');
  return _findDeserializerByTypeName(typeKey);
}

dynamic _dummyDeserializer(dynamic data) {
  return data;
}

Function? _findDeserializerByTypeName(String typeName) {
  if (typeName.startsWith('Map<')) {
    return _dummyDeserializer;
  }
  return _deserializers[typeName];
}

void initApis<T extends BaseApiDio, TDeserializer>(
  ApiInitializer<T, TDeserializer> initializer,
) {
  _initializer = initializer;
  for (var deserializer in initializer.modelDeserializers.entries) {
    final typeKey = deserializer.key.toString();
    _deserializers[typeKey] = deserializer.value;
  }
}

T api<T extends BaseApiDio>() {
  return _initializer!._findApi<T>();
}

/// this works as a tuple. No matter what params come in
typedef ErrorCallback = FutureOr<bool> Function(
  String? errorCode, [
  dynamic param2,
  dynamic param3,
  dynamic param4,
]);

class ContentTypeHeaders {
  static const String kMultipartFormData = 'multipart/form-data';
  static const String kApplicationJson = 'application/json';
}

class AcceptHeaders {
  static const String kApplicationJson = 'application/json';
}

class StatusCodeWrapper {
  int statusCode = -1;

  bool get isCache {
    return statusCode == 304;
  }
}

/// Extend this class for all apis
abstract class BaseApiDio {
  final String baseApiUrl;
  final int timeoutMillis;

  static Future clearCacheStore() async {
    final docDir = await getApplicationDocumentsDirectory();
    if (docDir.existsSync()) {
      await docDir.delete(recursive: true);
    }
  }

  int get utcOffsetMinutes {
    return DateTime.now().timeZoneOffset.inMinutes;
  }

  CacheOptions? _cacheOptions;

  /// might be required by interceptors
  CacheOptions? get cacheOptions => _cacheOptions;

  Future _createCacheOptionsIfNull() async {
    if (_cacheOptions == null) {
      if (!kIsWeb) {
        final docDir = await getApplicationDocumentsDirectory();
        _cacheOptions = CacheOptions(
          // store: MemCacheStore(),
          store: FileCacheStore(
            docDir.path,
          ),
          policy: CachePolicy.refreshForceCache,
          hitCacheOnErrorExcept: [401, 403, 500, 404],
          maxStale: const Duration(days: 10),
          priority: CachePriority.normal,
          cipher: null,
          keyBuilder: CacheOptions.defaultCacheKeyBuilder,
          allowPostMethod: true,
        );
      }
    }
  }

  BaseApiDio({
    required this.baseApiUrl,
    this.timeoutMillis = 60000,
  });

  static final Map<String, CancelToken> _cancelTokens = {};

  static void _cancelAllRequests() {
    for (var token in _cancelTokens.values) {
      try {
        token.cancel();
      } catch (_) {}
    }
  }

  /// might be required to cancel loop checks for async tasks. Because there is just no good
  /// way to cancel a loop in this case
  bool get hasAnyActiveRequests {
    return _cancelTokens.isNotEmpty && _cancelTokens.values.any((e) => e.isCancelled == false);
  }

  void cancelAllRequests() {
    _cancelAllRequests();
  }

  static void cancelAllRequestsStatic() {
    _cancelAllRequests();
  }

  /// Just checks if the previous request with the same path is
  /// still in progress. Sometimes it's necessary
  bool isPreviousRequestStillInProgress(String path) {
    final uri = Uri.parse(path);

    /// This means there is a cancellation token for the previous request.
    /// Once the request is complete (regardless of its status, the token is removed)
    return _cancelTokens[uri.path]?.isCancelled == false;
  }

  CancelToken _createNewCancelToken(path, String method) {
    final uri = Uri.parse(path);
    final key = '$method: ${uri.path}';
    if (_cancelTokens[key]?.isCancelled == false) {
      try {
        _cancelTokens[key]!.cancel();
      } catch (_) {}

      _cancelTokens.remove(key);
    }

    final token = CancelToken();
    _cancelTokens[key] = token;
    return token;
  }

  void _removeTokenAfterRequestHasFinished(
    String path,
    String method,
  ) {
    final uri = Uri.parse(path);
    _cancelTokens.remove('$method: ${uri.path}');
  }

  static void removeAllCancelledTokens() {
    // _cancelTokens.removeWhere((e) => e.isCancelled);
    _cancelTokens.removeWhere((key, value) => value.isCancelled);
  }

  Map<String, dynamic> _normalMapToFormMap(
    Map body,
  ) {
    Map<String, dynamic> map = {};
    body.forEach((key, value) {
      dynamic formValue;

      if (value is Uint8List) {
        formValue = dio.MultipartFile.fromBytes(
          value,
        );
      } else if (value is List<int>) {
        formValue = dio.MultipartFile.fromBytes(
          value,
        );
      } else if (value is io.File) {
        formValue = dio.MultipartFile.fromBytes(
          value.readAsBytesSync(),
          filename: basename(value.path),
        );
      } else if (value is DateTime) {
        formValue = value.toIso8601String();
      } else {
        formValue = value;
      }
      if (formValue != null) {
        map[key.toString()] = formValue;
      }
    });
    return map;
  }

  @protected
  List<dio.Interceptor> getInterceptors();

  /// e.g. if it's a List with a generic type it will return
  /// the name of the generic
  String _getTypeName<T>() {
    return T.toString().replaceAll('?', '');
  }

  T? _deserializeResponse<T>(
    Response<dynamic> response,
    bool loadAsBytes,
    Type? genericType,
  ) {
    if (T == Response) {
      return response as T;
    }
    final success = response.statusCode == 200 || response.statusCode == 304 || response.statusCode == 204;

    if (T == bool) {
      return success as T;
    }

    final typeName = _getTypeName<T>();

    if (success) {
      if (loadAsBytes && response.data is List<int>) {
        return response.data as T;
      } else if (response.data is Map) {
        final map = response.data as Map;
        if (T == bool) {
          return true as T;
        }
        final deserializer = _findDeserializerByTypeName(typeName);
        if (deserializer == null) {
          throw 'No deserializer found for $T';
        }
        return deserializer.call(map) as T;
      } else if (response.data is List) {
        final list = response.data as List;
        if (genericType != null) {
          final deserializer = _findDeserializerByTypeName(
            genericType.toString(),
          );
          final data = list.map((e) => deserializer!(e)).toList();
          return data as T;
        }

        return response.data as T;
      }
      if (response.data is num) {
        return response.data as T;
      } else if (response.data is T) {
        return response.data as T;
      }
    }
    return null;
  }

  /// [path] full path without base url e.g. /mobile/api/v1/...
  /// [isAbsolutePath] is true, it will not use a host from config but use the path as
  /// the full url
  /// [body] request body
  /// [errorCallback] passed to interceptor and called on errors
  /// [onSendProgress] if passed, can report upload progress
  /// [optionalHeaders] these headers will be added to a request via
  /// interceptor
  /// [files] files to send via form data (if backend api requires this way)
  /// [requestInterceptors] you can substitute the default interceptors by
  /// custom ones if necessary. These interceptors will completely replace
  /// all custom for the current request
  /// [contentType] application/json or multipart/form-data
  Future<T?> post<T>({
    required String path,
    bool isAbsolutePath = false,
    Object? body,
    ErrorCallback? errorCallback,
    dio.ProgressCallback? onSendProgress,
    Map<String, dynamic>? optionalHeaders,
    List<MapEntry<String, dio.MultipartFile>>? files,
    List<dio.Interceptor>? requestInterceptors,
    String contentType = ContentTypeHeaders.kApplicationJson,
    bool canUseCacheInterceptor = true,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    StatusCodeWrapper? statusCodeWrapper,
    Type? genericType,
  }) async {
    return _sendRequestWithBody<T>(
      path: path,
      isAbsolutePath: isAbsolutePath,
      body: body,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      contentType: contentType,
      canUseCacheInterceptor: canUseCacheInterceptor,
      errorCallback: errorCallback,
      method: 'POST',
      onSendProgress: onSendProgress,
      optionalHeaders: optionalHeaders,
      files: files,
      requestInterceptors: requestInterceptors,
      statusCodeWrapper: statusCodeWrapper,
      genericType: genericType,
    );
  }

  /// [path] full path without base url e.g. /mobile/api/v1/...
  /// [body] request body
  /// [errorCallback] passed to interceptor and called on errors
  /// [onSendProgress] if passed, can report upload progress
  /// [optionalHeaders] these headers will be added to a request via
  /// interceptor
  /// [platformFiles] files to send via form data (if backend api requires this way)
  /// [requestInterceptors] you can substitute the default interceptors by
  /// custom ones if necessary. These interceptors will completely replace
  /// all custom for the current request
  /// [contentType] application/json or multipart/form-data
  Future<T?> put<T>({
    required String path,
    bool isAbsolutePath = false,
    Object? body,
    ErrorCallback? errorCallback,
    Map<String, dynamic>? optionalHeaders,
    List<dio.Interceptor>? requestInterceptors,
    dio.ProgressCallback? onSendProgress,
    String contentType = ContentTypeHeaders.kApplicationJson,
    bool canUseCacheInterceptor = true,
    StatusCodeWrapper? statusCodeWrapper,
    Type? genericType,
  }) async {
    return _sendRequestWithBody<T>(
      path: path,
      isAbsolutePath: isAbsolutePath,
      canUseCacheInterceptor: canUseCacheInterceptor,
      errorCallback: errorCallback,
      body: body,
      contentType: contentType,
      method: 'PUT',
      onSendProgress: onSendProgress,
      optionalHeaders: optionalHeaders,
      requestInterceptors: requestInterceptors,
      statusCodeWrapper: statusCodeWrapper,
      genericType: genericType,
    );
  }

  /// [path] full path without base url e.g. /mobile/api/v1/...
  /// [body] request body
  /// [errorCallback] passed to interceptor and called on errors
  /// [onSendProgress] if passed, can report upload progress
  /// [optionalHeaders] these headers will be added to a request via
  /// interceptor
  /// [platformFiles] files to send via form data (if backend api requires this way)
  /// [requestInterceptors] you can substitute the default interceptors by
  /// custom ones if necessary. These interceptors will completely replace
  /// all custom for the current request
  /// [contentType] application/json or multipart/form-data
  Future<T?> patch<T>({
    required String path,
    bool isAbsolutePath = false,
    Map? body,
    ErrorCallback? errorCallback,
    Map<String, dynamic>? optionalHeaders,
    List<dio.Interceptor>? requestInterceptors,
    dio.ProgressCallback? onSendProgress,
    String contentType = ContentTypeHeaders.kApplicationJson,
    bool canUseCacheInterceptor = true,
    StatusCodeWrapper? statusCodeWrapper,
    Type? genericType,
  }) async {
    return _sendRequestWithBody<T>(
      path: path,
      isAbsolutePath: isAbsolutePath,
      canUseCacheInterceptor: canUseCacheInterceptor,
      errorCallback: errorCallback,
      body: body,
      contentType: contentType,
      method: 'PATCH',
      onSendProgress: onSendProgress,
      optionalHeaders: optionalHeaders,
      requestInterceptors: requestInterceptors,
      statusCodeWrapper: statusCodeWrapper,
      genericType: genericType,
    );
  }

  /// [path] full path without base url e.g. /mobile/api/v1/...
  /// [firstQuestionData] request body
  /// [errorCallback] passed to interceptor and called on errors
  /// [optionalHeaders] these headers will be added to a request via
  /// interceptor
  /// [platformFiles] files to send via form data (if backend api requires this way)
  /// [requestInterceptors] you can substitute the default interceptors by
  /// custom ones if necessary. These interceptors will completely replace
  /// all custom for the current request
  /// [contentType] application/json or multipart/form-data
  /// [statusCodeWrapper] If you pass this wrapper then a response
  /// status code will be saved there. This is only used tell cached requests from
  /// for now it is only used to return user profile
  Future<T?> get<T>({
    required String path,
    bool isAbsolutePath = false,
    bool canUseCacheInterceptor = true,
    ErrorCallback? errorCallback,
    String contentType = ContentTypeHeaders.kApplicationJson,
    Map<String, dynamic>? optionalHeaders,
    List<dio.Interceptor>? requestInterceptors,
    bool isSecure = true,
    StatusCodeWrapper? statusCodeWrapper,
    Type? genericType,
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) async {
    return _sendBodilessRequest<T>(
      path: path,
      isAbsolutePath: isAbsolutePath,
      method: 'GET',
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      canUseCacheInterceptor: canUseCacheInterceptor,
      contentType: contentType,
      errorCallback: errorCallback,
      optionalHeaders: optionalHeaders,
      requestInterceptors: requestInterceptors,
      isSecure: isSecure,
      statusCodeWrapper: statusCodeWrapper,
      genericType: genericType,
    );
  }

  Future<T?> delete<T>({
    required String path,
    bool isAbsolutePath = false,
    bool canUseCacheInterceptor = true,
    ErrorCallback? errorCallback,
    String contentType = ContentTypeHeaders.kApplicationJson,
    Map<String, dynamic>? optionalHeaders,
    List<dio.Interceptor>? requestInterceptors,
    bool isSecure = true,
    StatusCodeWrapper? statusCodeWrapper,
    Type? genericType,
  }) async {
    return _sendBodilessRequest<T>(
      path: path,
      isAbsolutePath: isAbsolutePath,
      method: 'DELETE',
      canUseCacheInterceptor: canUseCacheInterceptor,
      contentType: contentType,
      errorCallback: errorCallback,
      optionalHeaders: optionalHeaders,
      requestInterceptors: requestInterceptors,
      isSecure: isSecure,
      statusCodeWrapper: statusCodeWrapper,
      genericType: genericType,
    );
  }

  Future<T?> _sendBodilessRequest<T>({
    required String path,
    required bool isAbsolutePath,
    required String method,
    required String contentType,
    required ErrorCallback? errorCallback,
    required bool canUseCacheInterceptor,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    dio.ProgressCallback? onSendProgress,
    Map<String, dynamic>? optionalHeaders,
    required List<dio.Interceptor>? requestInterceptors,
    bool isSecure = true,
    required StatusCodeWrapper? statusCodeWrapper,
    Type? genericType,
    bool isCancellable = true,
  }) async {
    await _createCacheOptionsIfNull();
    final loadAsBytes = T == Uint8List;
    var base = baseApiUrl;
    if (isAbsolutePath) {
      final parsed = Uri.parse(path);
      base = parsed.origin;
      path = path.replaceFirst(base, '');
    }
    dio.Response response;
    dio.BaseOptions baseOptions = dio.BaseOptions(
      baseUrl: base,
      connectTimeout: connectTimeout ?? Duration(milliseconds: timeoutMillis),
      receiveTimeout: receiveTimeout ?? Duration(milliseconds: timeoutMillis),
      method: method,
      responseType: loadAsBytes ? dio.ResponseType.bytes : dio.ResponseType.json,
    );
    final String url = '$base$path';
    CancelToken? cancelToken = isCancellable ? _createNewCancelToken(path, method) : null;
    try {
      var interceptors = requestInterceptors ?? getInterceptors();

      for (var interceptor in interceptors) {
        if (interceptor is IMainInterceptor) {
          final mainInterceptor = interceptor as IMainInterceptor;
          mainInterceptor.errorCallback = errorCallback;
          mainInterceptor.contentType = contentType;
          mainInterceptor.addAuthenticationHeaders = isSecure;
        } else if (interceptor is IRepeatableInterceptor) {
          final repeatableInterceptor = interceptor as IRepeatableInterceptor;
          repeatableInterceptor.onTryAgain = () async {
            final result = await _sendBodilessRequest<Response>(
              isAbsolutePath: isAbsolutePath,
              path: path,
              canUseCacheInterceptor: canUseCacheInterceptor,
              contentType: contentType,
              errorCallback: errorCallback,
              method: method,
              requestInterceptors: interceptors,
              statusCodeWrapper: statusCodeWrapper,
              genericType: genericType,
              onSendProgress: onSendProgress,
              optionalHeaders: optionalHeaders,
              isSecure: isSecure,
              isCancellable: false,
            );
            return result;
          };
        }
      }

      final api = dio.Dio(baseOptions);
      api.acceptSelfSignedCertificate();
      api.interceptors.addAll(interceptors);

      if (optionalHeaders != null) {
        api.options.extra.addAll(optionalHeaders);
      }

      response = await api.request(
        url,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
    } catch (e, s) {
      _removeTokenAfterRequestHasFinished(path, method);
      _processException(e, s, url);
      if (T == bool) {
        return false as T;
      }
      return null;
    }
    _removeTokenAfterRequestHasFinished(path, method);
    if (T is Response) {
      return response as T;
    }
    return _deserializeResponse<T>(
      response,
      loadAsBytes,
      genericType,
    );
  }

  void onError(Map? error) {
    _initializer?.errorProcessor(error);
  }

  void _processException(
    Object e,
    StackTrace stackTrace,
    String url,
  ) {
    if (e is dio.DioException) {
      if (e.response?.data is Map) {
        var errorData = {...e.response!.data as Map};
        errorData['url'] = url;
        onError(errorData);
      } else {
        var value = e.response?.statusMessage ?? e.message;
        if (value?.contains('manually cancelled') == true) {
          /// a little hack to avoid new dio behavior for cancelled requests
          return;
        }
        onError({
          'error': value,
          'url': url,
        });
      }
    } else {
      var value = e.toString();
      onError({
        'error': value,
        'url': url,
      });
    }
  }

  Future<T?> _sendRequestWithBody<T>({
    required String path,
    Object? body,
    required String method,
    required String contentType,
    required ErrorCallback? errorCallback,
    required bool canUseCacheInterceptor,
    required bool isAbsolutePath,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    dio.ProgressCallback? onSendProgress,
    Map<String, dynamic>? optionalHeaders,
    List<MapEntry<String, dio.MultipartFile>>? files,
    required List<dio.Interceptor>? requestInterceptors,
    required StatusCodeWrapper? statusCodeWrapper,
    bool isCancellable = true,
    Type? genericType,
  }) async {
    await _createCacheOptionsIfNull();
    final loadAsBytes = T == Uint8List;
    var base = baseApiUrl;
    if (isAbsolutePath) {
      final parsed = Uri.parse(path);
      base = parsed.origin;
      path = path.replaceFirst(base, '');
    }
    dio.Response response;
    dio.BaseOptions baseOptions = dio.BaseOptions(
      baseUrl: base,
      connectTimeout: connectTimeout ?? Duration(milliseconds: timeoutMillis),
      receiveTimeout: receiveTimeout ?? Duration(milliseconds: timeoutMillis),
      method: method,
    );
    final String url = '$base$path';
    CancelToken? cancelToken = isCancellable ? _createNewCancelToken(path, method) : null;
    try {
      FormData? formData;
      Map<String, dynamic>? bodyAsMap;
      BodyType bodyType = BodyType.other;
      final sendAsFormData = contentType == ContentTypeHeaders.kMultipartFormData;
      if (body != null) {
        if (body is Map) {
          bodyType = BodyType.json;
          bodyAsMap = _normalMapToFormMap(body);
          if (sendAsFormData) {
            bodyType = BodyType.formData;
            formData = dio.FormData.fromMap(bodyAsMap);
          }
          if (files?.isNotEmpty == true && formData != null) {
            formData.files.addAll(files!);
          }
        } else {
          bodyType = BodyType.other;
        }
      }
      final interceptors = requestInterceptors ?? getInterceptors();
      for (var interceptor in interceptors) {
        if (interceptor is IMainInterceptor) {
          final mainInterceptor = interceptor as IMainInterceptor;
          mainInterceptor.errorCallback = errorCallback;
          mainInterceptor.contentType = contentType;
        } else if (interceptor is IRepeatableInterceptor) {
          final repeatableInterceptor = interceptor as IRepeatableInterceptor;
          repeatableInterceptor.onTryAgain = () async {
            final result = await _sendRequestWithBody<Response>(
              isAbsolutePath: isAbsolutePath,
              path: path,
              body: body,
              canUseCacheInterceptor: canUseCacheInterceptor,
              contentType: contentType,
              errorCallback: errorCallback,
              method: method,
              requestInterceptors: interceptors,
              statusCodeWrapper: statusCodeWrapper,
              files: files,
              genericType: genericType,
              onSendProgress: onSendProgress,
              isCancellable: false,
              optionalHeaders: optionalHeaders,
            );
            if (kDebugMode) {
              print('TRY AGAIN RESULT: $result');
            }
            return result;
          };
        }
      }

      final api = dio.Dio(baseOptions);
      api.acceptSelfSignedCertificate();
      api.interceptors.addAll(interceptors);
      if (optionalHeaders != null) {
        api.options.extra.addAll(optionalHeaders);
      }
      Object? data;
      if (bodyType == BodyType.json || bodyType == BodyType.formData) {
        data = sendAsFormData ? formData : bodyAsMap;
      } else {
        data = body;
      }
      response = await api.request(
        path,
        data: data,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
    } catch (e, s) {
      _removeTokenAfterRequestHasFinished(path, method);
      _processException(e, s, url);
      if (T == bool) {
        return false as T;
      }
      return null;
    }
    _removeTokenAfterRequestHasFinished(path, method);
    if (T is Response) {
      return response as T;
    }

    return _deserializeResponse<T>(
      response,
      loadAsBytes,
      genericType,
    );
  }
}

class ContentTypeStrings {
  static const String kJpeg = 'image/jpeg';
  static const String kPng = 'image/png';
  static const String kPdf = 'application/pdf';
  static const String kOctetStream = 'application/octet-stream';
}

enum BodyType {
  json,
  formData,
  other,
}

extension _DioExtension on dio.Dio {
  void acceptSelfSignedCertificate() {
    if (!kIsWeb) {
      httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (
            X509Certificate cert,
            String host,
            int port,
          ) {
            return true;
          };
          return client;
        },
      );
    }
  }
}
