// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thread_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller that exposes a single thread for a given post id, backed by the
/// [PostRepository.watchThread] stream so it can react to realtime updates.

@ProviderFor(ThreadController)
const threadControllerProvider = ThreadControllerFamily._();

/// Controller that exposes a single thread for a given post id, backed by the
/// [PostRepository.watchThread] stream so it can react to realtime updates.
final class ThreadControllerProvider
    extends $NotifierProvider<ThreadController, ThreadEntry> {
  /// Controller that exposes a single thread for a given post id, backed by the
  /// [PostRepository.watchThread] stream so it can react to realtime updates.
  const ThreadControllerProvider._({
    required ThreadControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'threadControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$threadControllerHash();

  @override
  String toString() {
    return r'threadControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ThreadController create() => ThreadController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThreadEntry value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThreadEntry>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ThreadControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$threadControllerHash() => r'e99cca54c253b579e6cf6039777b916a7386ed01';

/// Controller that exposes a single thread for a given post id, backed by the
/// [PostRepository.watchThread] stream so it can react to realtime updates.

final class ThreadControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ThreadController,
          ThreadEntry,
          ThreadEntry,
          ThreadEntry,
          String
        > {
  const ThreadControllerFamily._()
    : super(
        retry: null,
        name: r'threadControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Controller that exposes a single thread for a given post id, backed by the
  /// [PostRepository.watchThread] stream so it can react to realtime updates.

  ThreadControllerProvider call(String postId) =>
      ThreadControllerProvider._(argument: postId, from: this);

  @override
  String toString() => r'threadControllerProvider';
}

/// Controller that exposes a single thread for a given post id, backed by the
/// [PostRepository.watchThread] stream so it can react to realtime updates.

abstract class _$ThreadController extends $Notifier<ThreadEntry> {
  late final _$args = ref.$arg as String;
  String get postId => _$args;

  ThreadEntry build(String postId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<ThreadEntry, ThreadEntry>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThreadEntry, ThreadEntry>,
              ThreadEntry,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
