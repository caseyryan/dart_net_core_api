// ignore_for_file: depend_on_referenced_packages

import 'package:dart_core_doc_viewer/api/response_models/documentation_response/api_endpoint_model.dart';
import 'package:dart_core_doc_viewer/api/response_models/documentation_response/controller_api_model.dart';
import 'package:dart_core_doc_viewer/constants.dart';
import 'package:dart_core_doc_viewer/controllers/main_page_controller.dart';
import 'package:dart_core_doc_viewer/main_page/widgets/material_wrapper.dart';
import 'package:dart_core_doc_viewer/main_page/widgets/tiles/response_type_model.dart';
import 'package:dart_core_doc_viewer/ui/horizontal_line.dart';
import 'package:dart_core_doc_viewer/ui/text/caption.dart';
import 'package:dart_core_doc_viewer/ui/text/description.dart';
import 'package:dart_core_doc_viewer/ui/text/header.dart';
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
                    paddingTop: kPadding,
                    paddingLeft: kPadding,
                    paddingRight: kPadding,
                    paddingBottom: isLast && controllerApiModel?.hasTypes != true ? 40.0 : kPadding,
                  );
                }).toList(),
              ),
            ),
            if (controllerApiModel?.hasTypes == true)
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    const MaterialWrapper(
                      paddingTop: kPadding,
                      paddingLeft: kPadding,
                      paddingRight: kPadding,
                      paddingBottom: kPadding,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Header(
                                  text: 'Response models:',
                                  paddingBottom: 0.0,
                                  paddingTop: 0.0,
                                ),
                                Caption(
                                  text: 'This is the list of publicly available models used in responses of controller',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...controllerApiModel!.types!.mapIndexed(
                      (i, e) {
                        return ResponseTypeModel(
                          key: Key('response_type_$i'),
                          text: e,
                          paddingTop: kPadding,
                          paddingLeft: kPadding,
                          paddingRight: kPadding,
                          paddingBottom: kPadding,
                        );
                      },
                    ),
                    const SizedBox(
                      height: kPadding,
                    ),
                  ],
                ),
              )
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
