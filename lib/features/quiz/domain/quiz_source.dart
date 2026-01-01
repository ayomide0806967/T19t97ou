import '../../../models/quiz.dart';

/// Abstraction over quiz storage and retrieval.
///
/// This will let us swap from the current in-memory demo store to a
/// Supabase-backed implementation without touching UI.
abstract class QuizSource {
  List<QuizDraft> get drafts;
  List<QuizResultSummary> get results;
  List<QuizTakeQuestion> get sampleQuestions;

  List<QuizTakeQuestion>? questionsForTitle(String title);

  void saveDraft(QuizDraft draft);

  void recordPublishedQuiz({
    required String title,
    required List<QuizTakeQuestion> questions,
  });

  void deleteQuiz(String title);
}

