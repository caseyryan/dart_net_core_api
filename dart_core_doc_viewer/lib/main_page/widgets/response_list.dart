import 'package:dart_core_doc_viewer/api/response_models/documentation_response/controller_api_model.dart';
import 'package:dart_core_doc_viewer/ui/horizontal_line.dart';
import 'package:flutter/material.dart';

class ResponseList extends StatelessWidget {
  const ResponseList({
    super.key,
    required this.controllerApiModel,
  });

  final ControllerApiModel? controllerApiModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Endpoint Details'),
      ),
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Column(
          children: [
            HorizontalLine(),

          ],

        ),
      ),
    );
  }
}
