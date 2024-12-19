extension StringExtensions on String {
  String toSvgPath() => 'assets/svg/$this.svg';
  String toPngImagePath() => 'assets/images/$this.png';
  String toPngIconPath() => 'assets/icons/$this.png';
  String toJpgPath() => 'assets/images/$this.jpg';
}
