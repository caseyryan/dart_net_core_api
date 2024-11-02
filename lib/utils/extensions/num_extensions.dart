extension IntExtension on int {
  String padWithZeroes({
    int numZeroes = 6,
  }) {
    final thisString = toString();
    final int numZerosToAdd = numZeroes - thisString.length;
    final StringBuffer buffer = StringBuffer();
    for (var i = 0; i < numZerosToAdd; i++) {
      buffer.write('0');
    }
    buffer.write(thisString);
    return buffer.toString();
  }
}
