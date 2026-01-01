// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Latest authenticated user (or null) derived from [authStateProvider].

@ProviderFor(currentUser)
const currentUserProvider = CurrentUserProvider._();

/// Latest authenticated user (or null) derived from [authStateProvider].

final class CurrentUserProvider
    extends $FunctionalProvider<AppUser?, AppUser?, AppUser?>
    with $Provider<AppUser?> {
  /// Latest authenticated user (or null) derived from [authStateProvider].
  const CurrentUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  $ProviderElement<AppUser?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppUser? create(Ref ref) {
    return currentUser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppUser? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppUser?>(value),
    );
  }
}

String _$currentUserHash() => r'3415834fedd339364121191155ef84f3d4bacfe1';

/// Convenience provider for the current user's id (empty string if signed out).

@ProviderFor(currentUserId)
const currentUserIdProvider = CurrentUserIdProvider._();

/// Convenience provider for the current user's id (empty string if signed out).

final class CurrentUserIdProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Convenience provider for the current user's id (empty string if signed out).
  const CurrentUserIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserIdHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return currentUserId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$currentUserIdHash() => r'69980ad665f2f85346ffa6dcae32a23f585661ae';

/// Shared place to derive the current user's handle from their email.

@ProviderFor(currentUserHandle)
const currentUserHandleProvider = CurrentUserHandleProvider._();

/// Shared place to derive the current user's handle from their email.

final class CurrentUserHandleProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Shared place to derive the current user's handle from their email.
  const CurrentUserHandleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserHandleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserHandleHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return currentUserHandle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$currentUserHandleHash() => r'a7138896fa4988535d46a65cb1c5ba8f14e2115f';
