import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/quiz.dart';
import '../quiz/quiz_repository.dart';

/// Supabase implementation of [QuizRepository].
///
/// Uses the new schema tables:
/// - `quizzes` for quiz metadata and settings
/// - `quiz_questions` for questions with options
/// - `quiz_attempts` for tracking attempts with realtime support
/// - `quiz_responses` for individual question responses (offline sync)
/// - `quiz_results_view` for aggregated results
class SupabaseQuizRepository implements QuizRepository {
  SupabaseQuizRepository(this._client);

  final SupabaseClient _client;

  final List<QuizDraft> _drafts = <QuizDraft>[];
  final List<QuizResultSummary> _results = <QuizResultSummary>[];
  final Map<String, List<QuizTakeQuestion>> _questionsCache =
      <String, List<QuizTakeQuestion>>{};

  final StreamController<List<QuizDraft>> _draftsController =
      StreamController<List<QuizDraft>>.broadcast();
  final StreamController<List<QuizResultSummary>> _resultsController =
      StreamController<List<QuizResultSummary>>.broadcast();

  RealtimeChannel? _quizChannel;

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
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // Load drafts from new quizzes table
    final draftRows = await _client
        .from('quizzes')
        .select()
        .eq('author_id', userId)
        .inFilter('status', ['draft', 'published'])
        .order('updated_at', ascending: false);

    _drafts
      ..clear()
      ..addAll((draftRows as List).map((row) => _draftFromRow(row)));
    _emitDrafts();

    // Load results from quiz_results_view
    final resultRows = await _client
        .from('quiz_results_view')
        .select()
        .eq('author_id', userId)
        .order('created_at', ascending: false);

    _results
      ..clear()
      ..addAll((resultRows as List).map((row) => _resultFromRow(row)));
    _emitResults();
    
    // Subscribe to realtime quiz updates
    _subscribeToQuizzes(userId);
  }

  void _subscribeToQuizzes(String userId) {
    _quizChannel?.unsubscribe();
    _quizChannel = _client
        .channel('quizzes:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'quizzes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'author_id',
            value: userId,
          ),
          callback: (payload) => load(),
        )
        .subscribe();
  }

  @override
  List<QuizTakeQuestion>? questionsForTitle(String title) =>
      _questionsCache[title];

  /// Get questions for a quiz by its ID.
  Future<List<QuizTakeQuestion>> loadQuestions(String quizId) async {
    final rows = await _client
        .from('quiz_questions')
        .select()
        .eq('quiz_id', quizId)
        .order('order_index', ascending: true);

    final questions = (rows as List).map((row) => _questionFromRow(row)).toList();
    
    // Cache by quiz ID
    _questionsCache[quizId] = questions;
    return questions;
  }

  @override
  Future<void> saveDraft(QuizDraft draft) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Not signed in');
    }

    await _client.from('quizzes').upsert({
      'id': draft.id,
      'author_id': userId,
      'title': draft.title,
      'status': 'draft',
      'is_timed': draft.isTimed,
      'timer_minutes': draft.timerMinutes,
      'closing_date': draft.closingDate?.toIso8601String(),
      'require_pin': draft.requirePin,
      'pin': draft.pin,
      'visibility': draft.visibility,
      'updated_at': DateTime.now().toIso8601String(),
    });

    await load();
  }

  @override
  Future<void> deleteDraft(String draftId) async {
    await _client.from('quizzes').delete().eq('id', draftId);
    _drafts.removeWhere((d) => d.id == draftId);
    _emitDrafts();
  }

  @override
  Future<void> recordPublishedQuiz({
    required String title,
    required List<QuizTakeQuestion> questions,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Not signed in');
    }

    // Create quiz with 'published' status
    final quizInsert = await _client.from('quizzes').insert({
      'author_id': userId,
      'title': title,
      'status': 'published',
      'published_at': DateTime.now().toIso8601String(),
    }).select('id').single();

    final quizId = quizInsert['id'] as String;

    // Insert questions with JSONB options
    final questionRows = questions.asMap().entries.map((entry) {
      final q = entry.value;
      final options = q.options.asMap().entries.map((optEntry) => {
            'text': optEntry.value,
            'is_correct': optEntry.key == q.answerIndex,
          }).toList();

      return {
        'quiz_id': quizId,
        'order_index': entry.key,
        'prompt': q.prompt,
        'options': options,
        'question_type': 'multiple_choice',
        'points': 1,
      };
    });

    await _client.from('quiz_questions').insert(questionRows.toList());

    _questionsCache[title] = List.unmodifiable(questions);
    await load();
  }

  @override
  Future<void> deleteQuiz(String title) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('quizzes')
        .delete()
        .eq('author_id', userId)
        .eq('title', title);

    _results.removeWhere((r) => r.title == title);
    _questionsCache.remove(title);
    _emitResults();
  }

  // ============================================================================
  // Quiz Attempts (for taking quizzes)
  // ============================================================================

  /// Start a new quiz attempt.
  Future<String> startAttempt(String quizId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Not signed in');

    // Get current attempt count
    final existingAttempts = await _client
        .from('quiz_attempts')
        .select('attempt_number')
        .eq('quiz_id', quizId)
        .eq('user_id', userId)
        .order('attempt_number', ascending: false)
        .limit(1);

    final nextAttemptNumber = existingAttempts.isEmpty
        ? 1
        : ((existingAttempts[0]['attempt_number'] as int) + 1);

    final result = await _client.from('quiz_attempts').insert({
      'quiz_id': quizId,
      'user_id': userId,
      'attempt_number': nextAttemptNumber,
      'status': 'in_progress',
      'started_at': DateTime.now().toIso8601String(),
    }).select('id').single();

    return result['id'] as String;
  }

  /// Update heartbeat for live monitoring.
  Future<void> updateHeartbeat(String attemptId) async {
    await _client.rpc('update_attempt_heartbeat', params: {
      'p_attempt_id': attemptId,
    });
  }

  /// Submit a single response.
  Future<void> submitResponse({
    required String attemptId,
    required String questionId,
    required int selectedOptionIndex,
    int? timeSpentSeconds,
  }) async {
    await _client.from('quiz_responses').upsert({
      'attempt_id': attemptId,
      'question_id': questionId,
      'selected_option_index': selectedOptionIndex,
      'time_spent_seconds': timeSpentSeconds,
      'answered_at': DateTime.now().toIso8601String(),
    });
  }

  /// Sync multiple offline responses at once.
  Future<Map<String, dynamic>> syncOfflineResponses({
    required String attemptId,
    required List<Map<String, dynamic>> responses,
  }) async {
    final result = await _client.rpc('sync_quiz_responses', params: {
      'p_attempt_id': attemptId,
      'p_responses': responses,
    });
    return result as Map<String, dynamic>;
  }

  /// Submit the quiz attempt (finalize and grade).
  Future<Map<String, dynamic>> submitAttempt(String attemptId) async {
    final result = await _client.rpc('submit_quiz_attempt', params: {
      'p_attempt_id': attemptId,
    });
    return result as Map<String, dynamic>;
  }

  // ============================================================================
  // Live Monitoring (for quiz authors)
  // ============================================================================

  /// Watch live participants for a quiz.
  Stream<List<Map<String, dynamic>>> watchLiveParticipants(String quizId) {
    final controller = StreamController<List<Map<String, dynamic>>>();

    // Initial load
    _loadLiveParticipants(quizId).then(controller.add);

    // Subscribe to realtime changes
    final channel = _client
        .channel('quiz_live:$quizId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'quiz_attempts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'quiz_id',
            value: quizId,
          ),
          callback: (_) async {
            final participants = await _loadLiveParticipants(quizId);
            if (!controller.isClosed) controller.add(participants);
          },
        )
        .subscribe();

    controller.onCancel = () => channel.unsubscribe();
    return controller.stream;
  }

  Future<List<Map<String, dynamic>>> _loadLiveParticipants(String quizId) async {
    final rows = await _client
        .from('quiz_live_participants')
        .select()
        .eq('quiz_id', quizId);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  // ============================================================================
  // Helpers
  // ============================================================================

  QuizDraft _draftFromRow(Map<String, dynamic> row) {
    return QuizDraft(
      id: row['id'] as String,
      title: row['title'] as String? ?? '',
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '') ??
          DateTime.now(),
      questionCount: 0, // Will be computed from quiz_questions if needed
      isTimed: row['is_timed'] as bool? ?? false,
      timerMinutes: (row['timer_minutes'] as num?)?.toInt(),
      closingDate: row['closing_date'] != null
          ? DateTime.tryParse(row['closing_date'] as String)
          : null,
      requirePin: row['require_pin'] as bool? ?? false,
      pin: row['pin'] as String?,
      visibility: row['visibility'] as String? ?? 'public',
      restrictedAudience: null, // Handled differently now
    );
  }

  QuizResultSummary _resultFromRow(Map<String, dynamic> row) {
    return QuizResultSummary(
      title: row['title'] as String? ?? '',
      responses: (row['total_attempts'] as num?)?.toInt() ?? 0,
      averageScore: (row['average_score'] as num?)?.toDouble() ?? 0,
      completionRate: row['completed_count'] != null && row['total_attempts'] != null
          ? ((row['completed_count'] as num) / (row['total_attempts'] as num) * 100)
          : 0,
      lastUpdated: DateTime.tryParse(row['last_submission'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  QuizTakeQuestion _questionFromRow(Map<String, dynamic> row) {
    final options = (row['options'] as List<dynamic>?)
            ?.map((o) => (o as Map<String, dynamic>)['text'] as String? ?? '')
            .toList() ??
        <String>[];
    
    // Find the correct answer index
    int answerIndex = 0;
    final optionsList = row['options'] as List<dynamic>? ?? [];
    for (int i = 0; i < optionsList.length; i++) {
      if ((optionsList[i] as Map<String, dynamic>)['is_correct'] == true) {
        answerIndex = i;
        break;
      }
    }

    return QuizTakeQuestion(
      prompt: row['prompt'] as String? ?? '',
      options: options,
      answerIndex: answerIndex,
    );
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
    _quizChannel?.unsubscribe();
    _draftsController.close();
    _resultsController.close();
  }
}

