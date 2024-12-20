// ignore_for_file: depend_on_referenced_packages

import 'package:dart_core_doc_viewer/api/response_models/documentation_response/api_endpoint_model.dart';
import 'package:dart_core_doc_viewer/api/response_models/documentation_response/controller_api_model.dart';
import 'package:dart_core_doc_viewer/controllers/main_page_controller.dart';
import 'package:dart_core_doc_viewer/ui/horizontal_line.dart';
import 'package:dart_core_doc_viewer/ui/text/description.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:lite_forms/lite_forms.dart';

import 'tiles/endpoint_tile.dart';

class ResponseList extends StatelessWidget {
  const ResponseList({
    super.key,
  });

  ControllerApiModel? get controllerApiModel {
    return mainPageController.selectedController;
  }

  List<ApiEndpointModel> get endpoints {
    return mainPageController.endpoints;
  }

  Widget _buildEndpoints() {
    return LiteState<MainPageController>(
      builder: (BuildContext c, MainPageController controller) {
        if (endpoints.isNotEmpty != true) {
          return const Center(
            child: Description(text: 'Nothing is found'),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate(
                endpoints.mapIndexed((i, e) {
                  final isLast = i == endpoints.length - 1;
                  return EndpointTile(
                    key: Key('endpoint_$i'),
                    model: e,
                    paddingBottom: isLast ? 40.0 : 0.0,
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  String getTitle() {
    if (controllerApiModel == null) {
      return 'Endpoints';
    }
    return '${controllerApiModel?.getSafeTitle()} Endpoints';
  }

  @override
  Widget build(BuildContext context) {
    return LiteForm(
        name: 'endpointList',
        builder: (context, scrollController) {
          return Scaffold(
            appBar: AppBar(
              title: LiteSearchField(
                initialValue: mainPageController.endpointSearchValue,
                hintText: 'Filter endpoints...',
                onSearch: mainPageController.onEndpointSearch,
              ),
            ),
            body: SizedBox(
              height: double.infinity,
              width: double.infinity,
              child: Column(
                children: [
                  const HorizontalLine(),
                  Expanded(
                    child: _buildEndpoints(),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
