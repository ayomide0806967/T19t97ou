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
}
