import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Minimal local persistence for class admin roles.
/// Stores a map of class code -> list of admin handles.
class RolesService {
  static const String _key = 'class_admins_v1';

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

  /// Returns the admin handles for a class code.
  static Future<Set<String>> getAdminsFor(String classCode) async {
    final data = await _loadRaw();
    final list = data[classCode] ?? const <String>[];
    return list.toSet();
  }

  /// Saves the admin handles for a class code.
  static Future<void> saveAdminsFor(String classCode, Set<String> admins) async {
    final data = await _loadRaw();
    data[classCode] = admins.toList();
    await _saveRaw(data);
  }
}

