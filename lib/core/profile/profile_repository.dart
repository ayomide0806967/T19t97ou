import '../../models/user_profile.dart';

/// Domain-level contract for profile data access.
///
/// This interface decouples UI and business logic from specific storage
/// implementations (local SharedPreferences, Supabase, etc.).
abstract class ProfileRepository {
  /// The current user profile.
  UserProfile get profile;

  /// Stream of profile updates for reactive UIs.
  Stream<UserProfile> watchProfile();

  /// Load the profile from storage.
  Future<void> load();

  /// Update the profile in storage.
  Future<void> updateProfile(UserProfile profile);

  /// Update just the avatar image.
  /// [imageBytes] is the raw image data.
  /// Returns the new profile with updated avatar reference.
  Future<UserProfile> updateAvatar(List<int> imageBytes);

  /// Update just the header/banner image.
  /// [imageBytes] is the raw image data.
  /// Returns the new profile with updated header reference.
  Future<UserProfile> updateHeader(List<int> imageBytes);

  // =========================================================================
  // Follow operations
  // =========================================================================

  /// Toggle follow state for a user. Returns true if now following.
  Future<bool> toggleFollow(String targetUserId);

  /// Check if current user is following a target user.
  Future<bool> isFollowing(String targetUserId);

  /// Get follower count for a user.
  Future<int> getFollowerCount(String userId);

  /// Get following count for a user.
  Future<int> getFollowingCount(String userId);

  // =========================================================================
  // Profile lookup
  // =========================================================================

  /// Get a profile by user ID.
  Future<UserProfile?> getProfileById(String userId);

  /// Get a profile by handle.
  Future<UserProfile?> getProfileByHandle(String handle);
}

