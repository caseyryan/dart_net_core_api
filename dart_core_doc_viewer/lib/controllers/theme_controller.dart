// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:lite_state/lite_state.dart';

ThemeController get themeController {
  return findController<ThemeController>();
}

class ThemeController extends LiteStateController<ThemeController> {

  ThemeController() : super(preserveLocalStorageOnControllerDispose: true);

  ThemeMode get themeMode {
    return isDarkTheme ? ThemeMode.dark : ThemeMode.light;
  }

  Brightness get brightness {
    return isDarkTheme ? Brightness.dark : Brightness.light;
  }

  bool get isDarkTheme {
    return getPersistentValue<bool>('isDarkTheme') == true;
  }

  set isDarkTheme(bool value) {
    setPersistentValue('isDarkTheme', value);
  }

  void toggleTheme() {
    isDarkTheme = !isDarkTheme;
    rebuild();
  }

  void setTheme(bool isDark) {
    isDarkTheme = isDark;
    rebuild();
  }

  
  @override
  void reset() {
    
  }
  @override
  void onLocalStorageInitialized() {
    
  }
}