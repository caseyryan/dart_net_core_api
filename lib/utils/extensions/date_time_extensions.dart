extension DateTimeExtension on DateTime {
  DateTime addMinutes(int value) {
    return add(Duration(minutes: value));
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
