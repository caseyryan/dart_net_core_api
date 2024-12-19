import 'package:dart_core_doc_viewer/api/base_api_dio.dart';
import 'package:dart_core_doc_viewer/api/doc_api_dio.dart';
import 'package:dart_core_doc_viewer/api/response_models/documentation_response/documentation_response.dart';
import 'package:dart_core_doc_viewer/controllers/config_controller.dart';
import 'package:dart_core_doc_viewer/controllers/theme_controller.dart';
import 'package:dart_core_doc_viewer/main_page/main_page.dart';
import 'package:dart_core_doc_viewer/ui/themes/themes.dart';
import 'package:flutter/material.dart';
import 'package:lite_state/lite_state.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    initControllers({
      ConfigController: () => ConfigController(),
      ThemeController: () => ThemeController(),
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
              title: 'Api Documentation',
              theme: LightTheme.theme,
              darkTheme: DarkTheme.theme,
              themeMode: themeController.themeMode,
              home: const MainPage(),
            );
          },
        );
      },
    );
  }
}
