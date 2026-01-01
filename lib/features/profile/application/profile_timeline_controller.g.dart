// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_timeline_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProfileTimelineController)
const profileTimelineControllerProvider = ProfileTimelineControllerFamily._();

final class ProfileTimelineControllerProvider
    extends $NotifierProvider<ProfileTimelineController, ProfileTimelineState> {
  const ProfileTimelineControllerProvider._({
    required ProfileTimelineControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'profileTimelineControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$profileTimelineControllerHash();

  @override
  String toString() {
    return r'profileTimelineControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProfileTimelineController create() => ProfileTimelineController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileTimelineState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileTimelineState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProfileTimelineControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$profileTimelineControllerHash() =>
    r'f6622a2505c46b9c4840c8ee0497354559b6cff3';

final class ProfileTimelineControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ProfileTimelineController,
          ProfileTimelineState,
          ProfileTimelineState,
          ProfileTimelineState,
          String
        > {
  const ProfileTimelineControllerFamily._()
    : super(
        retry: null,
        name: r'profileTimelineControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProfileTimelineControllerProvider call(String handle) =>
      ProfileTimelineControllerProvider._(argument: handle, from: this);

  @override
  String toString() => r'profileTimelineControllerProvider';
}

abstract class _$ProfileTimelineController
    extends $Notifier<ProfileTimelineState> {
  late final _$args = ref.$arg as String;
  String get handle => _$args;

  ProfileTimelineState build(String handle);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<ProfileTimelineState, ProfileTimelineState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfileTimelineState, ProfileTimelineState>,
              ProfileTimelineState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
