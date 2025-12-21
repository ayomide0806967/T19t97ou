export '../models/quiz.dart';

import '../models/quiz.dart';

class QuizRepository {
  QuizRepository._();

  static final List<QuizDraft> _drafts = <QuizDraft>[
    QuizDraft(
      id: 'draft_1',
      title: 'Pharmacology night shift review',
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      questionCount: 6,
      isTimed: true,
      timerMinutes: 12,
      closingDate: DateTime.now().add(const Duration(days: 3)),
      requirePin: true,
      pin: '2345',
      visibility: 'followers',
      restrictedAudience: null,
    ),
    QuizDraft(
      id: 'draft_2',
      title: 'OB emergency drills',
      updatedAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      questionCount: 8,
      isTimed: false,
      closingDate: null,
      visibility: 'everyone',
    ),
  ];

  static final List<QuizResultSummary> _results = <QuizResultSummary>[
    QuizResultSummary(
      title: 'Cardio rounds checkpoint',
      responses: 42,
      averageScore: 86,
      completionRate: 0.93,
      lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    QuizResultSummary(
      title: 'Airway safety refresher',
      responses: 31,
      averageScore: 78,
      completionRate: 0.88,
      lastUpdated: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    ),
  ];

  static final List<QuizTakeQuestion> sampleQuestions = <QuizTakeQuestion>[
    const QuizTakeQuestion(
      prompt: 'Which parameter most immediately decreases when preload is reduced?',
      options: [
        'Stroke volume',
        'Afterload',
        'Heart rate',
        'Contractility',
      ],
      answerIndex: 0,
    ),
    const QuizTakeQuestion(
      prompt: 'Preferred first-line drug for stable narrow-complex SVT on the floor?',
      options: [
        'Amiodarone bolus',
        'Adenosine rapid IV push',
        'Procainamide infusion',
        'Magnesium sulfate',
      ],
      answerIndex: 1,
    ),
  ];

  // In-memory store of quizzes that have been published from the builder,
  // keyed by their title. This keeps the demo lightweight but lets us
  // reopen the actual questions later (e.g. from a class note).
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
