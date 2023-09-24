typedef DateParser = DateTime? Function(String value);

DateTime? defaultDateParser(String value) {
  return DateTime.tryParse(value);
}