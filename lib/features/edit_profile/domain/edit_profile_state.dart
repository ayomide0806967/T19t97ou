import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// State for the edit profile screen.
@immutable
class EditProfileState {
  const EditProfileState({
    this.headerImage,
    this.profileImage,
    this.name = '',
    this.bio = '',
    this.location = '',
    this.website = '',
    this.dateOfBirth,
    this.isPrivateAccount = false,
    this.tipsEnabled = false,
    this.isSaving = false,
    this.error,
  });

  final Uint8List? headerImage;
  final Uint8List? profileImage;
  final String name;
  final String bio;
  final String location;
  final String website;
  final DateTime? dateOfBirth;
  final bool isPrivateAccount;
  final bool tipsEnabled;
  final bool isSaving;
  final String? error;

  EditProfileState copyWith({
    Uint8List? headerImage,
    Uint8List? profileImage,
    String? name,
    String? bio,
    String? location,
    String? website,
    DateTime? dateOfBirth,
    bool? isPrivateAccount,
    bool? tipsEnabled,
    bool? isSaving,
    String? error,
  }) {
    return EditProfileState(
      headerImage: headerImage ?? this.headerImage,
      profileImage: profileImage ?? this.profileImage,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      website: website ?? this.website,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      isPrivateAccount: isPrivateAccount ?? this.isPrivateAccount,
      tipsEnabled: tipsEnabled ?? this.tipsEnabled,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}


/// Result returned when saving profile edits.
class EditProfileResult {
  const EditProfileResult({
    required this.headerImage,
    required this.profileImage,
    required this.name,
    required this.bio,
    required this.location,
    required this.website,
    required this.dateOfBirth,
    required this.isPrivateAccount,
    required this.tipsEnabled,
  });

  final Uint8List? headerImage;
  final Uint8List? profileImage;
  final String name;
  final String bio;
  final String location;
  final String website;
  final DateTime? dateOfBirth;
  final bool isPrivateAccount;
  final bool tipsEnabled;
}
