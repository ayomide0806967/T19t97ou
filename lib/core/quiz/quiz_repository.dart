import '../../models/quiz.dart';

/// Domain-level contract for quiz data access.
///
/// This interface decouples quiz-related UI and business logic from
/// specific storage implementations (local in-memory, Supabase, etc.).
abstract class QuizRepository {
  /// Get all quiz drafts.
  List<QuizDraft> get drafts;

  /// Get all quiz result summaries.
  List<QuizResultSummary> get results;

  /// Stream of drafts updates.
  Stream<List<QuizDraft>> watchDrafts();

  /// Stream of results updates.
  Stream<List<QuizResultSummary>> watchResults();

  /// Load data from storage.
  Future<void> load();

  /// Get questions for a published quiz by title.
  List<QuizTakeQuestion>? questionsForTitle(String title);

  /// Save or update a draft.
  Future<void> saveDraft(QuizDraft draft);

  /// Delete a draft by ID.
  Future<void> deleteDraft(String draftId);

  /// Record a published quiz with its questions.
  Future<void> recordPublishedQuiz({
    required String title,
    required List<QuizTakeQuestion> questions,
  });

  /// Delete a published quiz by title.
  Future<void> deleteQuiz(String title);
}
