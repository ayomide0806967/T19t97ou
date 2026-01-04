export '../models/quiz.dart';

import '../models/quiz.dart';

class QuizRepository {
  QuizRepository._();

  static final List<QuizDraft> _drafts = <QuizDraft>[];

  static final List<QuizResultSummary> _results = <QuizResultSummary>[];

  /// Sample questions were previously used for demo flows.
  /// In production, this should be provided by real quiz data.
  static final List<QuizTakeQuestion> sampleQuestions =
      <QuizTakeQuestion>[];

  // In-memory store of quizzes that have been published from the builder,
  // keyed by their title.
  static final Map<String, List<QuizTakeQuestion>> _publishedQuizzesByTitle =
      <String, List<QuizTakeQuestion>>{};

  static List<QuizDraft> get drafts => List.unmodifiable(_drafts);
  static List<QuizResultSummary> get results => List.unmodifiable(_results);
  static List<QuizTakeQuestion>? questionsForTitle(String title) =>
      _publishedQuizzesByTitle[title];

  static void saveDraft(QuizDraft draft) {
    final index = _drafts.indexWhere((d) => d.id == draft.id);
    if (index != -1) {
      _drafts[index] = draft;
    } else {
      _drafts.insert(0, draft);
    }
  }

  static void recordPublishedQuiz({
    required String title,
    required List<QuizTakeQuestion> questions,
  }) {
    final summary = QuizResultSummary(
      title: title,
      responses: 0,
      averageScore: 0,
      completionRate: 0,
      lastUpdated: DateTime.now(),
    );
    _results.insert(0, summary);
    _publishedQuizzesByTitle[title] =
        List<QuizTakeQuestion>.unmodifiable(questions);
  }

  static void deleteQuiz(String title) {
    _results.removeWhere((r) => r.title == title);
    _publishedQuizzesByTitle.remove(title);
  }
}
