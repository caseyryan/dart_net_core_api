import 'package:dart_core_doc_viewer/api/base_api_dio.dart';
import 'package:dart_core_doc_viewer/api/doc_api_dio.dart';
import 'package:dart_core_doc_viewer/api/response_models/documentation_response/documentation_response.dart';
import 'package:dart_core_doc_viewer/constants.dart';
import 'package:dart_core_doc_viewer/controllers/config_controller.dart';
import 'package:dart_core_doc_viewer/controllers/main_page_controller.dart';
import 'package:dart_core_doc_viewer/controllers/theme_controller.dart';
import 'package:dart_core_doc_viewer/main_page/main_page.dart';
import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_color_theme.dart';
import 'package:dart_core_doc_viewer/ui/themes/theme_extensions/custom_text_theme.dart';
import 'package:dart_core_doc_viewer/ui/themes/themes.dart';
import 'package:flutter/material.dart';
import 'package:lite_forms/lite_forms.dart';
import 'package:lite_forms/utils/lite_forms_configuration.dart';

import 'get_page_by_route_name.dart';
import 'ui/snack_bar_overlay.dart';

part 'parts/_init_lite_forms.dart';
part 'parts/_widget_builder.dart';
part 'parts/_generate_route.dart';

GlobalKey<NavigatorState> get navigatorKey => GlobalKey<NavigatorState>();

void main() {
  runApp(const App());
}


class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    initControllers({
      ConfigController: () => ConfigController(),
      ThemeController: () => ThemeController(),
      MainPageController: () => MainPageController(),
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LiteState<ConfigController>(
      onReady: (configController) {
        initApis(
          ApiInitializer(
            apis: [
              DocApiDio(
                baseApiUrl: configController.baseApiUrl,
              ),
            ],
            modelDeserializers: {
              DocumentationResponse: DocumentationResponse.deserialize,
            },
            errorProcessor: (Map? value) {},
          ),
        );
      },
      builder: (BuildContext c, ConfigController configController) {
        return LiteState<ThemeController>(
          builder: (BuildContext c, ThemeController themeController) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              title: 'Api Documentation',
              debugShowCheckedModeBanner: false,
              showPerformanceOverlay: false,
              theme: LightTheme.theme,
              darkTheme: DarkTheme.theme,
              themeMode: themeController.themeMode,
              initialRoute: MainPage.routeName,
              builder: _build,
              onGenerateRoute: _generateRoute,
            );
          },
        );
      },
    );
  }
}
