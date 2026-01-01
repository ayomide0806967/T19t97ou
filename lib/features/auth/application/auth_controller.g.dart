// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod-authenticated user stream that always emits the current user first.

@ProviderFor(authState)
const authStateProvider = AuthStateProvider._();

/// Riverpod-authenticated user stream that always emits the current user first.

final class AuthStateProvider
    extends
        $FunctionalProvider<AsyncValue<AppUser?>, AppUser?, Stream<AppUser?>>
    with $FutureModifier<AppUser?>, $StreamProvider<AppUser?> {
  /// Riverpod-authenticated user stream that always emits the current user first.
  const AuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<AppUser?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AppUser?> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'bb259ea7c4a5792814a2173fbb703df6b7d5e8d9';

/// Simple auth controller that forwards sign-in/up/out operations to the
/// underlying [AuthRepository], allowing UI to stay decoupled from
/// implementation details.
///
/// Exposes a lightweight [AuthUiState] so UI can react to loading/error.

@ProviderFor(AuthController)
const authControllerProvider = AuthControllerProvider._();

/// Simple auth controller that forwards sign-in/up/out operations to the
/// underlying [AuthRepository], allowing UI to stay decoupled from
/// implementation details.
///
/// Exposes a lightweight [AuthUiState] so UI can react to loading/error.
final class AuthControllerProvider
    extends $NotifierProvider<AuthController, AuthUiState> {
  /// Simple auth controller that forwards sign-in/up/out operations to the
  /// underlying [AuthRepository], allowing UI to stay decoupled from
  /// implementation details.
  ///
  /// Exposes a lightweight [AuthUiState] so UI can react to loading/error.
  const AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthUiState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthUiState>(value),
    );
  }
}

String _$authControllerHash() => r'9029d354ed1e19617634953a8d979686d321b0ab';

/// Simple auth controller that forwards sign-in/up/out operations to the
/// underlying [AuthRepository], allowing UI to stay decoupled from
/// implementation details.
///
/// Exposes a lightweight [AuthUiState] so UI can react to loading/error.

abstract class _$AuthController extends $Notifier<AuthUiState> {
  AuthUiState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AuthUiState, AuthUiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthUiState, AuthUiState>,
              AuthUiState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
