String deriveHandleFromEmail(
  String? email, {
  String fallback = '@yourprofile',
  int maxLength = 12,
}) {
  if (email == null || email.isEmpty) return fallback;
  String normalized = email
      .split('@')
      .first
      .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')
      .toLowerCase();
  if (normalized.isEmpty) return fallback;
  if (normalized.length > maxLength) {
    normalized = normalized.substring(0, maxLength);
  }
  return '@$normalized';
}

String ensureAtPrefix(String handle, {String fallback = '@yourprofile'}) {
  final trimmed = handle.trim();
  if (trimmed.isEmpty) return fallback;
  return trimmed.startsWith('@') ? trimmed : '@$trimmed';
}

