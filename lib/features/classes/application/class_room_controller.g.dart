// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_room_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller responsible for class membership/admin state for a single class.
///
/// This centralizes logic that was previously scattered across widget state
/// in the iOS messages "College" screen, so UI can stay focused on rendering.

@ProviderFor(ClassRoomController)
const classRoomControllerProvider = ClassRoomControllerFamily._();

/// Controller responsible for class membership/admin state for a single class.
///
/// This centralizes logic that was previously scattered across widget state
/// in the iOS messages "College" screen, so UI can stay focused on rendering.
final class ClassRoomControllerProvider
    extends $NotifierProvider<ClassRoomController, ClassRoomState> {
  /// Controller responsible for class membership/admin state for a single class.
  ///
  /// This centralizes logic that was previously scattered across widget state
  /// in the iOS messages "College" screen, so UI can stay focused on rendering.
  const ClassRoomControllerProvider._({
    required ClassRoomControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'classRoomControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$classRoomControllerHash();

  @override
  String toString() {
    return r'classRoomControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ClassRoomController create() => ClassRoomController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClassRoomState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClassRoomState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClassRoomControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$classRoomControllerHash() =>
    r'3f7c91a11b4275c527bde3247754b02fb37a0896';

/// Controller responsible for class membership/admin state for a single class.
///
/// This centralizes logic that was previously scattered across widget state
/// in the iOS messages "College" screen, so UI can stay focused on rendering.

final class ClassRoomControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ClassRoomController,
          ClassRoomState,
          ClassRoomState,
          ClassRoomState,
          String
        > {
  const ClassRoomControllerFamily._()
    : super(
        retry: null,
        name: r'classRoomControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Controller responsible for class membership/admin state for a single class.
  ///
  /// This centralizes logic that was previously scattered across widget state
  /// in the iOS messages "College" screen, so UI can stay focused on rendering.

  ClassRoomControllerProvider call(String classCode) =>
      ClassRoomControllerProvider._(argument: classCode, from: this);

  @override
  String toString() => r'classRoomControllerProvider';
}

/// Controller responsible for class membership/admin state for a single class.
///
/// This centralizes logic that was previously scattered across widget state
/// in the iOS messages "College" screen, so UI can stay focused on rendering.

abstract class _$ClassRoomController extends $Notifier<ClassRoomState> {
  late final _$args = ref.$arg as String;
  String get classCode => _$args;

  ClassRoomState build(String classCode);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<ClassRoomState, ClassRoomState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ClassRoomState, ClassRoomState>,
              ClassRoomState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
