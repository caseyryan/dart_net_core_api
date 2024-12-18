import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
import 'package:dart_net_core_api/exports.dart';

class DocumentationController extends ApiController {
  DocumentationController(this.documentationService);

  final ApiDocumentationService documentationService;

  @HttpGet('/documentation')
  Future<Map> getDocumentationJson() async {
    // throw BadRequestException(message: 'message');
    return await documentationService.tryGetDocumentationForCurrentEnvironment();
  }
}
