// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_topic_posts_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller that exposes posts for a given class topic tag, with simple
/// paging semantics used by the iOS "topic notes" feed.

@ProviderFor(ClassTopicPostsController)
const classTopicPostsControllerProvider = ClassTopicPostsControllerFamily._();

/// Controller that exposes posts for a given class topic tag, with simple
/// paging semantics used by the iOS "topic notes" feed.
final class ClassTopicPostsControllerProvider
    extends $NotifierProvider<ClassTopicPostsController, ClassTopicPostsState> {
  /// Controller that exposes posts for a given class topic tag, with simple
  /// paging semantics used by the iOS "topic notes" feed.
  const ClassTopicPostsControllerProvider._({
    required ClassTopicPostsControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'classTopicPostsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$classTopicPostsControllerHash();

  @override
  String toString() {
    return r'classTopicPostsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ClassTopicPostsController create() => ClassTopicPostsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClassTopicPostsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClassTopicPostsState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClassTopicPostsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$classTopicPostsControllerHash() =>
    r'272e08f957ccbb17d364dc4ed852ff186310a090';

/// Controller that exposes posts for a given class topic tag, with simple
/// paging semantics used by the iOS "topic notes" feed.

final class ClassTopicPostsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ClassTopicPostsController,
          ClassTopicPostsState,
          ClassTopicPostsState,
          ClassTopicPostsState,
          String
        > {
  const ClassTopicPostsControllerFamily._()
    : super(
        retry: null,
        name: r'classTopicPostsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Controller that exposes posts for a given class topic tag, with simple
  /// paging semantics used by the iOS "topic notes" feed.

  ClassTopicPostsControllerProvider call(String topicTag) =>
      ClassTopicPostsControllerProvider._(argument: topicTag, from: this);

  @override
  String toString() => r'classTopicPostsControllerProvider';
}

/// Controller that exposes posts for a given class topic tag, with simple
/// paging semantics used by the iOS "topic notes" feed.

abstract class _$ClassTopicPostsController
    extends $Notifier<ClassTopicPostsState> {
  late final _$args = ref.$arg as String;
  String get topicTag => _$args;

  ClassTopicPostsState build(String topicTag);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<ClassTopicPostsState, ClassTopicPostsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ClassTopicPostsState, ClassTopicPostsState>,
              ClassTopicPostsState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
