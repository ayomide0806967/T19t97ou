import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Stores invite codes per class code and provides helpers to generate/validate.
class InvitesService {
  static const String _key = 'class_invite_codes_v1';
  static const String _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final Random _rng = Random();

  static Future<Map<String, String>> _loadRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <String, String>{};
    try {
      final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return <String, String>{};
    }
  }

  static Future<void> _saveRaw(Map<String, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(map));
  }

  static String _generateCode([int length = 6]) {
    return List.generate(length, (_) => _alphabet[_rng.nextInt(_alphabet.length)])
        .join();
  }

  /// Returns the existing code for the class or generates and saves a new one.
  static Future<String> getOrCreateCode(String classCode) async {
    final data = await _loadRaw();
    final existing = data[classCode];
    if (existing != null && existing.isNotEmpty) return existing;
    final code = _generateCode();
    data[classCode] = code;
    await _saveRaw(data);
    return code;
  }

  /// Returns all saved invite codes mapping.
  static Future<Map<String, String>> getAllCodes() => _loadRaw();

  /// Attempts to resolve an invite code to a class code; returns null if not found.
  static Future<String?> resolve(String inviteCode) async {
    final lookup = (inviteCode.trim().toUpperCase());
    final data = await _loadRaw();
    for (final entry in data.entries) {
      if (entry.value.toUpperCase() == lookup) return entry.key;
    }
    return null;
  }
}

