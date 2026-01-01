import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/class_invites_source.dart';

/// Local SharedPreferences-backed implementation of [ClassInvitesSource].
class LocalClassInvitesSource implements ClassInvitesSource {
  static const String _key = 'class_invite_codes_v1';
  static const String _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final Random _rng = Random();

  Future<Map<String, String>> _loadRaw() async {
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

  Future<void> _saveRaw(Map<String, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(map));
  }

  String _generateCode([int length = 6]) {
    return List.generate(length, (_) => _alphabet[_rng.nextInt(_alphabet.length)])
        .join();
  }

  @override
  Future<String> getOrCreateCode(String classCode) async {
    final data = await _loadRaw();
    final existing = data[classCode];
    if (existing != null && existing.isNotEmpty) return existing;
    final code = _generateCode();
    data[classCode] = code;
    await _saveRaw(data);
    return code;
  }

  @override
  Future<Map<String, String>> getAllCodes() => _loadRaw();

  @override
  Future<String?> resolve(String inviteCode) async {
    final lookup = inviteCode.trim().toUpperCase();
    final data = await _loadRaw();
    for (final entry in data.entries) {
      if (entry.value.toUpperCase() == lookup) return entry.key;
    }
    return null;
  }
}

