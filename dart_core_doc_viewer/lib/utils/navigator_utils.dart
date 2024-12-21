import 'package:dart_core_doc_viewer/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


NavigatorState get navigatorState {
  return navigatorKey.currentState!;
}

BuildContext get appContext {
  return navigatorKey.currentContext!;
}

Future<T?> pushNamed<T extends Object?>(
  String routeName, {
  Object? arguments,
  bool popPrevious = false,
}) async {
  if (popPrevious) {
    pop();
  }
  if (kDebugMode) {
    print('pushNamed($routeName)');
  }
  return navigatorState.pushNamed<T>(
    routeName,
    arguments: arguments,
  );
}

Future<T?> push<T extends Object?>(
  Route<T> route, {
  bool popPrevious = false,
}) {
  if (kDebugMode) {
    print('push()');
  }
  if (popPrevious) {
    pop();
  }
  return navigatorState.push<T>(
    route,
  );
}

Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
  String routeName, {
  Object? arguments,
}) async {
  if (kDebugMode) {
    print('pushNamedAndRemoveUntil()');
  }
  return navigatorState.pushNamedAndRemoveUntil<T>(
    routeName,
    (route) => false,
    arguments: arguments,
  );
}

void pop<T extends Object?>([T? result]) {
  if (kDebugMode) {
    print('pop()');
  }
  return navigatorState.pop<T>(result);
}

Future<bool> maybePop<T extends Object?>([T? result]) async {
  if (kDebugMode) {
    print('maybePop()');
  }
  return navigatorState.maybePop<T>(result);
}

bool get canPop {
  return navigatorState.canPop();
}

bool isFullScreenDialog(BuildContext context) {
  final route = ModalRoute.of(context);
  if (route is CupertinoPageRoute) {
    return route.fullscreenDialog;
  } else if (route is MaterialPageRoute) {
    return route.fullscreenDialog;
  }

  return false;
}
