import 'package:dart_net_core_api/utils/intl_local/lib/intl.dart';

extension DateTimeExtension on DateTime {
  DateTime addMinutes(int value) {
    return add(Duration(minutes: value));
  }

  String toUnderscoreDateTime() {
    return DateFormat('dd_MM_yyyy_hh_mm_ss').format(this);
  }

  DateTime subtractMinutes(int value) {
    return addMinutes(-value);
  }

  DateTime addHours(int value) {
    return add(Duration(minutes: value));
  }

  DateTime subtractHours(int value) {
    return addHours(-value);
  }
}
