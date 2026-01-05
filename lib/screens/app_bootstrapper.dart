import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/app_providers.dart';
import '../features/auth/application/session_providers.dart';

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

  void _bootstrapForUser(String userId) {
    unawaited(ref.read(profileRepositoryProvider).load());
    unawaited(ref.read(quizRepositoryProvider).load());
    // Reload the feed to pick up per-user interactions (likes/bookmarks).
    unawaited(ref.read(postRepositoryProvider).load());
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId.isEmpty) {
      _lastUserId = null;
      return widget.child;
    }

    if (_lastUserId != userId) {
      _lastUserId = userId;
      Future.microtask(() {
        if (!mounted) return;
        if (_lastUserId != userId) return;
        _bootstrapForUser(userId);
      });
    }

    return widget.child;
  }
}
