part of 'tweet_post_card.dart';

String _initialsFrom(String value) {
  final letters = value.replaceAll(RegExp('[^A-Za-z]'), '');
  if (letters.isEmpty) return 'IN';
  final count = letters.length >= 2 ? 2 : 1;
  return letters.substring(0, count).toUpperCase();
}

String _formatMetric(int value) {
  if (value >= 1000000) {
    final formatted = value / 1000000;
    return '${formatted.toStringAsFixed(formatted.truncateToDouble() == formatted ? 0 : 1)}M';
  }
  if (value >= 1000) {
    final formatted = value / 1000;
    return '${formatted.toStringAsFixed(formatted.truncateToDouble() == formatted ? 0 : 1)}K';
  }
  return value.toString();
}

