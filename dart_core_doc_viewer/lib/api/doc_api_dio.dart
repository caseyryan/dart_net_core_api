// ignore_for_file: implementation_imports

import 'package:dart_core_doc_viewer/api/response_models/documentation_response/documentation_response.dart';
import 'package:dio/dio.dart';

import 'base_api_dio.dart';

class DocApiDio extends BaseApiDio {
  DocApiDio({
    required super.baseApiUrl,
    super.timeoutMillis = 60000,
  });

  Future<DocumentationResponse?> getDocumentation() async {
    final response = await get<DocumentationResponse>(
      path: '/api/v1/documentation',
    );
    return response;
  }

  @override
  List<Interceptor> getInterceptors() {
    return [
      LogInterceptor(
        error: true,
        request: true,
        requestBody: true,
        responseBody: true,
        requestHeader: true,
      ),
    ];
  }
}
