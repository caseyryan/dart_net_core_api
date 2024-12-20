part of '../main.dart';

Widget _build(
  BuildContext c,
  Widget? widget,
) {
  
  _initLiteForms(c);
  return Stack(
    children: <Widget>[
      widget ?? const SizedBox.shrink(),
      const SnackbarOverlay(),
      // const LocalAuthOverlay(),
    ],
  );
}
