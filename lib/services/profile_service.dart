import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

class ProfileService extends ChangeNotifier {
  static const String _storageKey = 'user_profile';

  UserProfile _profile = const UserProfile(
    fullName: 'Alex Rivera',
    handle: '@productlead',
    bio:
        'Guiding nursing and midwifery teams through safe practice, exam preparation, and compassionate leadership across our teaching hospital.',
    profession: 'Clinical Educator',
    avatarImageBase64: null,
    headerImageBase64: null,
  );

  UserProfile get profile => _profile;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      _profile = UserProfile.decode(raw);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to decode profile: $e');
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    _profile = profile;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, profile.encode());
  }
}
