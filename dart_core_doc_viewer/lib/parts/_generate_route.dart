part of '../main.dart';


Route<dynamic>? _generateRoute(
  RouteSettings routeSettings,
) {
  bool fullScreenDialog = isFullScreenDialog(
    routeSettings.name,
  );
  bool maintain = maintainState(
    routeSettings.name!,
  );
  final page = getPageByRouteName(
    routeSettings.name!,
    routeSettings.arguments,
  );
  return MaterialPageRoute(
    builder: (c) {
      return page;
    },
    fullscreenDialog: fullScreenDialog,
    maintainState: maintain,
  );
}
