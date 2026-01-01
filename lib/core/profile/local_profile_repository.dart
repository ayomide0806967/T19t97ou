import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_profile.dart';
import 'profile_repository.dart';

/// Local storage implementation of [ProfileRepository].
///
/// Uses SharedPreferences for persistence and stores images as Base64.
/// This is suitable for offline/local-only mode.
class LocalProfileRepository implements ProfileRepository {
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

  final StreamController<UserProfile> _controller =
      StreamController<UserProfile>.broadcast();

  @override
  UserProfile get profile => _profile;

  @override
  Stream<UserProfile> watchProfile() => _controller.stream;

  @override
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      _profile = UserProfile.decode(raw);
      _emit();
    } catch (_) {
      // Ignore decode errors, keep default
    }
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    _profile = profile;
    _emit();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, profile.encode());
  }

  @override
  Future<UserProfile> updateAvatar(List<int> imageBytes) async {
    final base64 = base64Encode(imageBytes);
    final updated = _profile.copyWith(avatarImageBase64: base64);
    await updateProfile(updated);
    return updated;
  }

  @override
  Future<UserProfile> updateHeader(List<int> imageBytes) async {
    final base64 = base64Encode(imageBytes);
    final updated = _profile.copyWith(headerImageBase64: base64);
    await updateProfile(updated);
    return updated;
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(_profile);
    }
  }

  void dispose() {
    _controller.close();
  }
}
