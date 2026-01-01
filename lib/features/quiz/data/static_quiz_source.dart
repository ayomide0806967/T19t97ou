import '../../../models/quiz.dart';
import '../../../services/quiz_repository.dart' as legacy;
import '../domain/quiz_source.dart';

/// Adapter that exposes the existing static QuizRepository through the
/// QuizSource abstraction.
class StaticQuizSource implements QuizSource {
  @override
  List<QuizDraft> get drafts => legacy.QuizRepository.drafts;

  @override
  List<QuizResultSummary> get results => legacy.QuizRepository.results;

  @override
  List<QuizTakeQuestion> get sampleQuestions =>
      legacy.QuizRepository.sampleQuestions;

  @override
  List<QuizTakeQuestion>? questionsForTitle(String title) =>
      legacy.QuizRepository.questionsForTitle(title);

  @override
  void deleteQuiz(String title) {
    legacy.QuizRepository.deleteQuiz(title);
  }

  @override
  void recordPublishedQuiz({
    required String title,
    required List<QuizTakeQuestion> questions,
  }) {
    legacy.QuizRepository.recordPublishedQuiz(
      title: title,
      questions: questions,
    );
  }

  @override
  void saveDraft(QuizDraft draft) {
    legacy.QuizRepository.saveDraft(draft);
  }
}

