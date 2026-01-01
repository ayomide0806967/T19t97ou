import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/di/app_providers.dart';
import '../../feed/domain/post_repository.dart';
import '../../../models/thread_entry.dart';

part 'thread_controller.g.dart';

/// Controller that exposes a single thread for a given post id, backed by the
/// [PostRepository.watchThread] stream so it can react to realtime updates.
@riverpod
class ThreadController extends _$ThreadController {
  StreamSubscription<ThreadEntry>? _subscription;

  PostRepository get _repository => ref.read(postRepositoryProvider);

  @override
  ThreadEntry build(String postId) {
    final initial = _repository.buildThreadForPost(postId);

    _subscription ??=
        _repository.watchThread(postId).listen((ThreadEntry thread) {
      state = thread;
    });

    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
    });

    return initial;
  }
}

