// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Primary quiz source provider.
///
/// For now this wraps the existing in-memory static implementation, but
/// later we can swap in a Supabase-backed source here.

@ProviderFor(quizSource)
const quizSourceProvider = QuizSourceProvider._();

/// Primary quiz source provider.
///
/// For now this wraps the existing in-memory static implementation, but
/// later we can swap in a Supabase-backed source here.

final class QuizSourceProvider
    extends $FunctionalProvider<QuizSource, QuizSource, QuizSource>
    with $Provider<QuizSource> {
  /// Primary quiz source provider.
  ///
  /// For now this wraps the existing in-memory static implementation, but
  /// later we can swap in a Supabase-backed source here.
  const QuizSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quizSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quizSourceHash();

  @$internal
  @override
  $ProviderElement<QuizSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  QuizSource create(Ref ref) {
    return quizSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuizSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuizSource>(value),
    );
  }
}

String _$quizSourceHash() => r'537877b11cec36137d2921587f2f7959ad39e54e';
