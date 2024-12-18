import 'package:dart_net_core_api/exports.dart';

class DocumentationController extends ApiController {
  DocumentationController(this.documentationService);

  final ApiDocumentationService documentationService;

  @HttpGet('/documentation')
  Future<Map> getDocumentationJson() async {
    return await documentationService.tryGetDocumentationForCurrentEnvironment();
  }
}