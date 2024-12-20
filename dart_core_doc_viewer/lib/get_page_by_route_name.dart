import 'package:dart_core_doc_viewer/main_page/main_page.dart';
import 'package:flutter/material.dart';

bool isFullScreenDialog(String? routeName) {
  switch (routeName) {
    case MainPage.routeName:
      return true;
  }
  return false;
}

bool maintainState(String routeName) {
  return false;
}

Widget getPageByRouteName(
  String routeName,
  Object? arguments,
) {
  Widget page;
  switch (routeName) {
    default:
      page = _getDefaultPage();
      break;
  }
  return page;
}

Widget _getDefaultPage() {
  return const MainPage();
}
