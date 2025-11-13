import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Minimal local persistence for class membership.
/// Stores a map of class code -> list of member handles.
class MembersService {
  static const String _key = 'class_members_v1';

  static Future<Map<String, List<String>>> _loadRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <String, List<String>>{};
    try {
      final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, (v as List).cast<String>()));
    } catch (_) {
      return <String, List<String>>{};
    }
  }

  static Future<void> _saveRaw(Map<String, List<String>> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(map));
  }

  static Future<Set<String>> getMembersFor(String classCode) async {
    final data = await _loadRaw();
    final list = data[classCode] ?? const <String>[];
    return list.toSet();
  }

  static Future<void> saveMembersFor(String classCode, Set<String> members) async {
    final data = await _loadRaw();
    data[classCode] = members.toList();
    await _saveRaw(data);
  }
}

