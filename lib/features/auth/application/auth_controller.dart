import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/di/app_providers.dart';
import 'auth_ui_state.dart';

part 'auth_controller.g.dart';

/// Riverpod-authenticated user stream that always emits the current user first.
@riverpod
Stream<AppUser?> authState(Ref ref) async* {
  final authRepository = ref.watch(authRepositoryProvider);
  // Emit the current user immediately so initial build has a value.
  yield authRepository.currentUser;
  // Then forward all subsequent auth state changes.
  yield* authRepository.authStateChanges;
}

/// Simple auth controller that forwards sign-in/up/out operations to the
/// underlying [AuthRepository], allowing UI to stay decoupled from
/// implementation details.
///
/// Exposes a lightweight [AuthUiState] so UI can react to loading/error.
@riverpod
class AuthController extends _$AuthController {
  @override
  AuthUiState build() => const AuthUiState();

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.signInWithGoogle();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.signOut();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.signInWithEmailPassword(email, password);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> signUpWithEmailPassword(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.signUpWithEmailPassword(email, password);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
}
