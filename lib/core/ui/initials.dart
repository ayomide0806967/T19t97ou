String initialsFrom(
  String value, {
  String fallback = 'IN',
  int maxLetters = 2,
}) {
  final letters = value.replaceAll(RegExp('[^A-Za-z]'), '');
  if (letters.isEmpty) return fallback;
  final count = letters.length >= maxLetters ? maxLetters : letters.length;
  return letters.substring(0, count).toUpperCase();
}

