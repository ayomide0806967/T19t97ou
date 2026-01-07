import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/di/app_providers.dart';
import '../../../models/quiz.dart';
import '../take/quiz_take_screen.dart';

class QuizJoinScreen extends ConsumerStatefulWidget {
  const QuizJoinScreen({super.key});

  @override
  ConsumerState<QuizJoinScreen> createState() => _QuizJoinScreenState();
}

class _QuizJoinScreenState extends ConsumerState<QuizJoinScreen> {
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _linkController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  static String? _extractQuizId(String raw) {
    final input = raw.trim();
    if (input.isEmpty) return null;

    final uri = Uri.tryParse(input);
    if (uri != null) {
      if (uri.queryParameters.containsKey('quizId')) {
        final id = uri.queryParameters['quizId']?.trim();
        if (id != null && id.isNotEmpty) return id;
      }
      if (uri.pathSegments.isNotEmpty) {
        final last = uri.pathSegments.last.trim();
        if (last.isNotEmpty) return last;
      }
    }

    return input;
  }

  static bool _looksLikeUuid(String value) {
    final v = value.trim();
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(v);
  }

  Future<void> _join() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      if (!AppConfig.hasSupabaseConfig) {
        throw StateError('Supabase is not configured');
      }

      final quizId = _extractQuizId(_linkController.text);
      if (quizId == null || !_looksLikeUuid(quizId)) {
        throw StateError('Enter a valid quiz link or ID');
      }

      final client = ref.read(supabaseClientProvider);

      final quizRow = await client
          .from('quizzes')
          .select(
            'id, title, description, status, is_timed, timer_minutes, require_pin, pin, closing_date',
          )
          .eq('id', quizId)
          .maybeSingle();

      if (quizRow == null) {
        throw StateError('Quiz not found');
      }
      if (quizRow['status'] != 'published') {
        throw StateError('This quiz is not published yet');
      }

      final closing = quizRow['closing_date'] as String?;
      if (closing != null) {
        final closingDate = DateTime.tryParse(closing);
        if (closingDate != null && DateTime.now().isAfter(closingDate)) {
          throw StateError('This quiz is closed');
        }
      }

      final requirePin = quizRow['require_pin'] as bool? ?? false;
      final pin = (quizRow['pin'] as String?)?.trim();
      if (requirePin) {
        final entered = _pinController.text.trim();
        if (entered.isEmpty) {
          throw StateError('Enter the quiz PIN');
        }
        if (pin != null && pin.isNotEmpty && entered != pin) {
          throw StateError('Incorrect PIN');
        }
      }

      final questionRows = await client
          .from('quiz_questions')
          .select('prompt, options, order_index')
          .eq('quiz_id', quizId)
          .order('order_index', ascending: true);

      final questions = (questionRows as List)
          .cast<Map<String, dynamic>>()
          .map((row) {
            final prompt = row['prompt'] as String? ?? '';
            final optionsRaw = row['options'] as List<dynamic>? ?? const [];
            final options = optionsRaw
                .map((o) => (o as Map<String, dynamic>)['text'] as String? ?? '')
                .toList(growable: false);
            int answerIndex = 0;
            for (int i = 0; i < optionsRaw.length; i++) {
              if ((optionsRaw[i] as Map<String, dynamic>)['is_correct'] == true) {
                answerIndex = i;
                break;
              }
            }
            return QuizTakeQuestion(
              prompt: prompt,
              options: options,
              answerIndex: answerIndex,
            );
          })
          .where((q) => q.prompt.trim().isNotEmpty && q.options.isNotEmpty)
          .toList(growable: false);

      if (questions.isEmpty) {
        throw StateError('This quiz has no questions');
      }

      if (!mounted) return;

      final title = quizRow['title'] as String? ?? 'Quiz';
      final description = quizRow['description'] as String? ?? '';
      final isTimed = quizRow['is_timed'] as bool? ?? false;
      final timerMinutes = (quizRow['timer_minutes'] as num?)?.toInt();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizTakeScreen(
            title: title,
            subtitle: description,
            questions: questions,
            isTimed: isTimed,
            timerMinutes: timerMinutes,
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('StateError: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color surface = isDark ? const Color(0xFF0E0F12) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        title: const Text('Join quiz'),
        backgroundColor: surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: 'Quiz link or ID',
                hintText: 'Paste the quiz link (or UUID)',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              decoration: const InputDecoration(
                labelText: 'PIN (if required)',
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _join(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _join,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Join'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

