// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'college_screen_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CollegeScreenController)
const collegeScreenControllerProvider = CollegeScreenControllerFamily._();

final class CollegeScreenControllerProvider
    extends $NotifierProvider<CollegeScreenController, CollegeUiState> {
  const CollegeScreenControllerProvider._({
    required CollegeScreenControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'collegeScreenControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$collegeScreenControllerHash();

  @override
  String toString() {
    return r'collegeScreenControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CollegeScreenController create() => CollegeScreenController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CollegeUiState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CollegeUiState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CollegeScreenControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$collegeScreenControllerHash() =>
    r'9aacf3b91581c53c6a4e99f8ac29e5bf95531409';

final class CollegeScreenControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          CollegeScreenController,
          CollegeUiState,
          CollegeUiState,
          CollegeUiState,
          String
        > {
  const CollegeScreenControllerFamily._()
    : super(
        retry: null,
        name: r'collegeScreenControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CollegeScreenControllerProvider call(String classCode) =>
      CollegeScreenControllerProvider._(argument: classCode, from: this);

  @override
  String toString() => r'collegeScreenControllerProvider';
}

abstract class _$CollegeScreenController extends $Notifier<CollegeUiState> {
  late final _$args = ref.$arg as String;
  String get classCode => _$args;

  CollegeUiState build(String classCode);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<CollegeUiState, CollegeUiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CollegeUiState, CollegeUiState>,
              CollegeUiState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
