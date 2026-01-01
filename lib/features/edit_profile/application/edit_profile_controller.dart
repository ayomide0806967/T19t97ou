import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/edit_profile_state.dart';

/// Controller for edit profile screen business logic.
///
/// Uses Riverpod 3.0 Notifier pattern for state management.
class EditProfileController extends Notifier<EditProfileState> {
  late String _initialName;
  late String _initialBio;
  final ImagePicker _picker = ImagePicker();

  @override
  EditProfileState build() {
    final params = ref.read(_paramsProvider);
    _initialName = params.initialName;
    _initialBio = params.initialBio;
    return EditProfileState(
      name: params.initialName,
      bio: params.initialBio,
      headerImage: params.initialHeaderImage,
      profileImage: params.initialProfileImage,
    );
  }

  /// Whether there are unsaved changes.
  bool get hasChanges {
    if (state.name.trim() != _initialName.trim()) return true;
    if (state.bio.trim() != _initialBio.trim()) return true;
    if (state.location.trim().isNotEmpty) return true;
    if (state.website.trim().isNotEmpty) return true;
    if (state.dateOfBirth != null) return true;
    if (state.isPrivateAccount) return true;
    return false;
  }

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateBio(String bio) {
    state = state.copyWith(bio: bio);
  }

  void updateLocation(String location) {
    state = state.copyWith(location: location);
  }

  void updateWebsite(String website) {
    state = state.copyWith(website: website);
  }

  void updateDateOfBirth(DateTime? dob) {
    state = state.copyWith(dateOfBirth: dob);
  }

  void togglePrivateAccount(bool value) {
    state = state.copyWith(isPrivateAccount: value);
  }

  void toggleTips(bool value) {
    state = state.copyWith(tipsEnabled: value);
  }

  Future<void> pickHeaderImage() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    state = state.copyWith(headerImage: bytes);
  }

  Future<void> pickProfileImage() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    state = state.copyWith(profileImage: bytes);
  }

  EditProfileResult save() {
    state = state.copyWith(isSaving: true);
    String bio = state.bio.trim();
    if (bio.length > 160) {
      bio = bio.substring(0, 160);
    }
    return EditProfileResult(
      headerImage: state.headerImage,
      profileImage: state.profileImage,
      name: state.name.trim(),
      bio: bio,
      location: state.location.trim(),
      website: state.website.trim(),
      dateOfBirth: state.dateOfBirth,
      isPrivateAccount: state.isPrivateAccount,
      tipsEnabled: state.tipsEnabled,
    );
  }
}

/// Parameters for creating an edit profile controller.
@immutable
class EditProfileParams {
  const EditProfileParams({
    required this.initialName,
    required this.initialBio,
    this.initialHeaderImage,
    this.initialProfileImage,
  });

  final String initialName;
  final String initialBio;
  final Uint8List? initialHeaderImage;
  final Uint8List? initialProfileImage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditProfileParams &&
          runtimeType == other.runtimeType &&
          initialName == other.initialName &&
          initialBio == other.initialBio;

  @override
  int get hashCode => initialName.hashCode ^ initialBio.hashCode;
}

/// Internal provider to hold the parameters.
final _paramsProvider = Provider<EditProfileParams>((ref) {
  throw UnimplementedError('_paramsProvider must be overridden');
});

/// Provider for edit profile controller.
final editProfileControllerProvider =
    NotifierProvider<EditProfileController, EditProfileState>(
  EditProfileController.new,
);

/// Helper to create a scoped provider with parameters.
List<Override> editProfileOverrides(EditProfileParams params) => [
      _paramsProvider.overrideWithValue(params),
    ];
