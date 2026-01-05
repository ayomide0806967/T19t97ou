import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/app_providers.dart';
import '../features/auth/application/auth_controller.dart';

/// Runs lightweight side-effects that should happen when auth state changes.
///
/// This avoids blocking Flutter Web boot on network operations (which would
/// otherwise keep the HTML splash visible), while still ensuring repositories
/// get (re)loaded once a session is available.
class AppBootstrapper extends ConsumerStatefulWidget {
  const AppBootstrapper({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends ConsumerState<AppBootstrapper> {
  String? _lastUserId;
  ProviderSubscription<AsyncValue<AppUser?>>? _authSubscription;

  @override
  void initState() {
    super.initState();

    _authSubscription = ref.listenManual<AsyncValue<AppUser?>>(
      authStateProvider,
      (prev, next) {
        final user = next.value;
        final userId = user?.id;
        if (userId == null || userId.isEmpty) {
          _lastUserId = null;
          return;
        }
        if (_lastUserId == userId) return;
        _lastUserId = userId;

        unawaited(ref.read(profileRepositoryProvider).load());
        unawaited(ref.read(quizRepositoryProvider).load());
        // Reload the feed to pick up per-user interactions (likes/bookmarks).
        unawaited(ref.read(postRepositoryProvider).load());
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _authSubscription?.close();
    _authSubscription = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
