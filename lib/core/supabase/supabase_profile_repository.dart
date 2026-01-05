import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_profile.dart';
import '../profile/profile_repository.dart';

/// Supabase implementation of [ProfileRepository].
///
/// Stores profile data in Supabase `profiles` table and images in
/// Supabase Storage bucket `avatars`.
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  UserProfile _profile = const UserProfile(
    fullName: '',
    handle: '',
    bio: '',
    profession: '',
  );

  final StreamController<UserProfile> _controller =
      StreamController<UserProfile>.broadcast();

  RealtimeChannel? _profileChannel;

  @override
  UserProfile get profile => _profile;

  @override
  Stream<UserProfile> watchProfile() => _controller.stream;

  @override
  Future<void> load() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (row != null) {
      _profile = _fromRow(row);
      _emit();
    }

    // Subscribe to realtime profile changes
    _subscribeToProfile(userId);
  }

  void _subscribeToProfile(String userId) {
    _profileChannel?.unsubscribe();
    _profileChannel = _client
        .channel('profile:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) {
              _profile = _fromRow(payload.newRecord);
              _emit();
            }
          },
        )
        .subscribe();
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Not signed in');
    }

    await _client.from('profiles').upsert({
      'id': userId,
      'full_name': profile.fullName,
      'handle': profile.handle,
      'bio': profile.bio,
      'profession': profile.profession,
    });

    _profile = profile;
    _emit();
  }

  @override
  Future<UserProfile> updateAvatar(List<int> imageBytes) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Not signed in');
    }

    final path = '$userId/avatar.jpg';
    await _client.storage.from('avatars').uploadBinary(
          path,
          Uint8List.fromList(imageBytes),
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
            cacheControl: '3600',
          ),
        );

    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
    final versionedUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

    await _client.from('profiles').update({
      'avatar_url': versionedUrl,
    }).eq('id', userId);

    _profile = _profile.copyWith(avatarImageBase64: versionedUrl);
    _emit();
    return _profile;
  }

  @override
  Future<UserProfile> updateHeader(List<int> imageBytes) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Not signed in');
    }

    final path = '$userId/header.jpg';
    await _client.storage.from('avatars').uploadBinary(
          path,
          Uint8List.fromList(imageBytes),
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
            cacheControl: '3600',
          ),
        );

    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
    final versionedUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

    await _client.from('profiles').update({
      'header_url': versionedUrl,
    }).eq('id', userId);

    _profile = _profile.copyWith(headerImageBase64: versionedUrl);
    _emit();
    return _profile;
  }

  // ============================================================================
  // Follows functionality
  // ============================================================================

  /// Follow another user by their profile ID.
  Future<bool> followUser(String targetUserId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    if (userId == targetUserId) return false; // Can't follow yourself

    try {
      await _client.from('follows').insert({
        'follower_id': userId,
        'following_id': targetUserId,
      });
      return true;
    } catch (e) {
      // Already following
      return false;
    }
  }

  /// Unfollow a user.
  Future<bool> unfollowUser(String targetUserId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    await _client
        .from('follows')
        .delete()
        .eq('follower_id', userId)
        .eq('following_id', targetUserId);
    return true;
  }

  /// Toggle follow state. Returns true if now following, false if unfollowed.
  Future<bool> toggleFollow(String targetUserId) async {
    final isCurrentlyFollowing = await isFollowing(targetUserId);
    if (isCurrentlyFollowing) {
      await unfollowUser(targetUserId);
      return false;
    } else {
      await followUser(targetUserId);
      return true;
    }
  }

  /// Check if current user is following a target user.
  Future<bool> isFollowing(String targetUserId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final result = await _client
        .from('follows')
        .select('id')
        .eq('follower_id', userId)
        .eq('following_id', targetUserId)
        .maybeSingle();

    return result != null;
  }

  /// Get follower count for a user.
  Future<int> getFollowerCount(String userId) async {
    final result = await _client
        .from('follows')
        .select('id')
        .eq('following_id', userId);
    return (result as List).length;
  }

  /// Get following count for a user.
  Future<int> getFollowingCount(String userId) async {
    final result = await _client
        .from('follows')
        .select('id')
        .eq('follower_id', userId);
    return (result as List).length;
  }

  /// Get list of user IDs that the current user follows.
  Future<List<String>> getFollowingIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final result = await _client
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);

    return (result as List)
        .map((row) => row['following_id'] as String)
        .toList();
  }

  /// Get list of user IDs that follow the current user.
  Future<List<String>> getFollowerIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final result = await _client
        .from('follows')
        .select('follower_id')
        .eq('following_id', userId);

    return (result as List)
        .map((row) => row['follower_id'] as String)
        .toList();
  }

  // ============================================================================
  // Profile lookup helpers
  // ============================================================================

  /// Get a profile by user ID.
  Future<UserProfile?> getProfileById(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (row == null) return null;
    return _fromRow(row);
  }

  /// Get a profile by handle.
  Future<UserProfile?> getProfileByHandle(String handle) async {
    final normalizedHandle = handle.startsWith('@') ? handle : '@$handle';
    final row = await _client
        .from('profiles')
        .select()
        .eq('handle', normalizedHandle)
        .maybeSingle();

    if (row == null) return null;
    return _fromRow(row);
  }

  UserProfile _fromRow(Map<String, dynamic> row) {
    return UserProfile(
      fullName: (row['full_name'] as String?) ?? '',
      handle: (row['handle'] as String?) ?? '',
      bio: (row['bio'] as String?) ?? '',
      profession: (row['profession'] as String?) ?? '',
      avatarImageBase64: row['avatar_url'] as String?,
      headerImageBase64: row['header_url'] as String?,
    );
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(_profile);
    }
  }

  void dispose() {
    _profileChannel?.unsubscribe();
    _controller.close();
  }
}
