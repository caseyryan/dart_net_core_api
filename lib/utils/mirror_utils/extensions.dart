

extension SymbolExtension on Symbol {
  static final RegExp _regExp = RegExp(r'(?<=Symbol\(")[a-zA-Z0-9_]+');

  String toName() {
    final name = toString();
    final match = _regExp.firstMatch(name);
    if (match == null) {
      return '';
    }
    return name.substring(
      match.start,
      match.end,
    );
  }
}


