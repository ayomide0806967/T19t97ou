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
    fullName: '',
    handle: '',
    bio: '',
    profession: '',
    avatarImageBase64: null,
    headerImageBase64: null,
  );

  final StreamController<UserProfile> _controller =
      StreamController<UserProfile>.broadcast();

  // Local mock for following state (local mode only)
  final Set<String> _following = {};

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

  // =========================================================================
  // Follow operations (local mock - for offline mode)
  // =========================================================================

  @override
  Future<bool> toggleFollow(String targetUserId) async {
    if (_following.contains(targetUserId)) {
      _following.remove(targetUserId);
      return false;
    } else {
      _following.add(targetUserId);
      return true;
    }
  }

  @override
  Future<bool> isFollowing(String targetUserId) async {
    return _following.contains(targetUserId);
  }

  @override
  Future<int> getFollowerCount(String userId) async {
    // Local mode doesn't track other users' followers
    return 0;
  }

  @override
  Future<int> getFollowingCount(String userId) async {
    // Return count of local following set if checking current user
    return _following.length;
  }

  // =========================================================================
  // Profile lookup (local mock - for offline mode)
  // =========================================================================

  @override
  Future<UserProfile?> getProfileById(String userId) async {
    // Local mode only knows about the current user's profile
    return null;
  }

  @override
  Future<UserProfile?> getProfileByHandle(String handle) async {
    // Local mode only knows about the current user's profile
    if (handle == _profile.handle) {
      return _profile;
    }
    return null;
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

