import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/static_quiz_source.dart';
import '../domain/quiz_source.dart';

part 'quiz_providers.g.dart';

/// Primary quiz source provider.
///
/// For now this wraps the existing in-memory static implementation, but
/// later we can swap in a Supabase-backed source here.
@riverpod
QuizSource quizSource(Ref ref) {
  return StaticQuizSource();
}
