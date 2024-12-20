
extension StringExtensions on String {
  String toSvgPath() => 'assets/svg/$this.svg';
  String toPngImagePath() => 'assets/images/$this.png';
  String toPngIconPath() => 'assets/icons/$this.png';
  String toJpgPath() => 'assets/images/$this.jpg';

  String splitByCamelCase() {
    var words = split(RegExp(r"(?=[A-Z])"));
    return words.map((e) => _capitalizeString(e)).join(' ');
  }

  

  String _capitalizeString(String string) {
    if (string.isEmpty) return string;
    return "${string[0].toUpperCase()}${string.substring(1)}";
  }
}
