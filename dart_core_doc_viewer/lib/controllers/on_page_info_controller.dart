import 'package:lite_state/lite_state.dart';

OnPageInfoController get onPageInfoController {
  return findController<OnPageInfoController>();
}

class OnPageInfoController extends LiteStateController<OnPageInfoController> {
  OnPageInfoController() : super(preserveLocalStorageOnControllerDispose: true);

  int get _versionNumber {
    return getPersistentValue<int>('versionKey') ?? 0;
  }

  void resetVersion() {
    setPersistentValue('versionKey', _versionNumber + 1);
  }

  bool isDismissed(String labelName) {
    return getPersistentValue<bool>('$labelName$_versionNumber') == true;
  }

  Future dismiss(String labelName) async {
    await setPersistentValue('$labelName$_versionNumber', true);
    rebuild();
  }

  @override
  void onLocalStorageInitialized() {}

  @override
  void reset() {}
}
