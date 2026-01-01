import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/user/handle.dart';
import 'auth_controller.dart';

part 'session_providers.g.dart';

/// Latest authenticated user (or null) derived from [authStateProvider].
@riverpod
AppUser? currentUser(Ref ref) {
  final asyncUser = ref.watch(authStateProvider);
  return asyncUser.value;
}

/// Convenience provider for the current user's id (empty string if signed out).
@riverpod
String currentUserId(Ref ref) {
  final user = ref.watch(currentUserProvider);
  return user?.id ?? '';
}

/// Shared place to derive the current user's handle from their email.
@riverpod
String currentUserHandle(Ref ref) {
  final user = ref.watch(currentUserProvider);
  return deriveHandleFromEmail(user?.email);
}

