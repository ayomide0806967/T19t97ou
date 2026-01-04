import 'dart:async';

import '../../models/quiz.dart';
import 'quiz_repository.dart';

/// Local in-memory implementation of [QuizRepository].
///
/// Uses demo data and keeps state in memory. Suitable for offline/demo mode.
class LocalQuizRepository implements QuizRepository {
  final List<QuizDraft> _drafts = <QuizDraft>[];

  final List<QuizResultSummary> _results = <QuizResultSummary>[];

  final Map<String, List<QuizTakeQuestion>> _publishedQuizzesByTitle =
      <String, List<QuizTakeQuestion>>{};

  final StreamController<List<QuizDraft>> _draftsController =
      StreamController<List<QuizDraft>>.broadcast();
  final StreamController<List<QuizResultSummary>> _resultsController =
      StreamController<List<QuizResultSummary>>.broadcast();

  @override
  List<QuizDraft> get drafts => List.unmodifiable(_drafts);

  @override
  List<QuizResultSummary> get results => List.unmodifiable(_results);

  @override
  Stream<List<QuizDraft>> watchDrafts() => _draftsController.stream;

  @override
  Stream<List<QuizResultSummary>> watchResults() => _resultsController.stream;

  @override
  Future<void> load() async {
    // Demo data is already initialized. Emit initial state.
    _emitDrafts();
    _emitResults();
  }

  @override
  List<QuizTakeQuestion>? questionsForTitle(String title) =>
      _publishedQuizzesByTitle[title];

  @override
  Future<void> saveDraft(QuizDraft draft) async {
    final index = _drafts.indexWhere((d) => d.id == draft.id);
    if (index != -1) {
      _drafts[index] = draft;
    } else {
      _drafts.insert(0, draft);
    }
    _emitDrafts();
  }

  @override
  Future<void> deleteDraft(String draftId) async {
    _drafts.removeWhere((d) => d.id == draftId);
    _emitDrafts();
  }

  @override
  Future<void> recordPublishedQuiz({
    required String title,
    required List<QuizTakeQuestion> questions,
  }) async {
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
    _emitResults();
  }

  @override
  Future<void> deleteQuiz(String title) async {
    _results.removeWhere((r) => r.title == title);
    _publishedQuizzesByTitle.remove(title);
    _emitResults();
  }

  void _emitDrafts() {
    if (!_draftsController.isClosed) {
      _draftsController.add(List.unmodifiable(_drafts));
    }
  }

  void _emitResults() {
    if (!_resultsController.isClosed) {
      _resultsController.add(List.unmodifiable(_results));
    }
  }

  void dispose() {
    _draftsController.close();
    _resultsController.close();
  }
}
