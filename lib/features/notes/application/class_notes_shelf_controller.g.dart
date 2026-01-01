// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_notes_shelf_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ClassNotesShelfController)
const classNotesShelfControllerProvider = ClassNotesShelfControllerFamily._();

final class ClassNotesShelfControllerProvider
    extends $NotifierProvider<ClassNotesShelfController, ClassNotesShelfState> {
  const ClassNotesShelfControllerProvider._({
    required ClassNotesShelfControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'classNotesShelfControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$classNotesShelfControllerHash();

  @override
  String toString() {
    return r'classNotesShelfControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ClassNotesShelfController create() => ClassNotesShelfController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClassNotesShelfState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClassNotesShelfState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClassNotesShelfControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$classNotesShelfControllerHash() =>
    r'e09e20c8ea4de9b384fac125999f37e16c347bc3';

final class ClassNotesShelfControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ClassNotesShelfController,
          ClassNotesShelfState,
          ClassNotesShelfState,
          ClassNotesShelfState,
          String
        > {
  const ClassNotesShelfControllerFamily._()
    : super(
        retry: null,
        name: r'classNotesShelfControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClassNotesShelfControllerProvider call(String classCode) =>
      ClassNotesShelfControllerProvider._(argument: classCode, from: this);

  @override
  String toString() => r'classNotesShelfControllerProvider';
}

abstract class _$ClassNotesShelfController
    extends $Notifier<ClassNotesShelfState> {
  late final _$args = ref.$arg as String;
  String get classCode => _$args;

  ClassNotesShelfState build(String classCode);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<ClassNotesShelfState, ClassNotesShelfState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ClassNotesShelfState, ClassNotesShelfState>,
              ClassNotesShelfState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
