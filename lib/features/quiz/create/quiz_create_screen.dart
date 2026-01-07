import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/quiz.dart';
import '../../../core/config/app_config.dart';
import '../../../core/di/app_providers.dart';
import '../aiken/aiken_import_models.dart';
import '../aiken/aiken_import_review_screen.dart';
import '../results/quiz_results_screen.dart';
import '../ui/quiz_labeled_field.dart';
import '../ui/quiz_palette.dart';
import 'import/pdf_text_extractor.dart';
import 'import/word_text_extractor.dart';
import 'models/quiz_question_fields.dart';
import '../application/quiz_providers.dart';

part 'quiz_create_screen_actions.dart';
part 'quiz_create_screen_build.dart';
part 'quiz_create_screen_cards.dart';
part 'quiz_create_screen_step_details.dart';
part 'quiz_create_screen_step_settings.dart';
part 'quiz_create_screen_step_question_setup.dart';
part 'quiz_create_screen_step_question_editing.dart';

enum QuizVisibility { everyone, followers }

enum _QuizBuildMode { manual, aiken }

/// Revamped Quiz Creation Screen with rail-based vertical stepper
/// Design inspired by the note creation flow
class QuizCreateScreen extends ConsumerStatefulWidget {
  const QuizCreateScreen({
    super.key,
    this.returnToCallerOnPublish = false,
    this.initialTitle,
    this.initialQuestions,
  });

  final bool returnToCallerOnPublish;
  final String? initialTitle;
  final List<QuizTakeQuestion>? initialQuestions;

  @override
  ConsumerState<QuizCreateScreen> createState() => _QuizCreateScreenState();
}

abstract class _QuizCreateScreenStateBase
    extends ConsumerState<QuizCreateScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _draftQuizId;

  // Which step is currently being edited
  // 0 = Details, 1 = Settings, 2 = Question setup, 3+ = Questions
  int _activeStep = 0;

  // Controllers for Details step
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Settings step state
  bool _isTimed = true;
  double _timeLimitMinutes = 20;
  bool _hasDeadline = false;
  DateTime? _closingDate;
  int? _attemptLimit;
  bool _requiresPin = false;
  final TextEditingController _timeLimitController = TextEditingController(
    text: '20',
  );
  final TextEditingController _pinController = TextEditingController();
  final QuizVisibility _visibility = QuizVisibility.everyone;
  _QuizBuildMode _buildMode = _QuizBuildMode.manual;

  // Questions
  final List<QuizQuestionFields> _questions = <QuizQuestionFields>[];

  // Track which steps have been completed
  bool _detailsCompleted = false;
  bool _settingsCompleted = false;
  bool _questionSetupCompleted = false;

  // Keys for scrolling/focusing specific steps
  final GlobalKey _detailsStepKey = GlobalKey();
  final GlobalKey _settingsStepKey = GlobalKey();
  final GlobalKey _setupStepKey = GlobalKey();
  final GlobalKey _firstQuestionStepKey = GlobalKey();
  final List<GlobalKey> _questionStepKeys = <GlobalKey>[];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null && widget.initialTitle!.trim().isNotEmpty) {
      _titleController.text = widget.initialTitle!.trim();
      _detailsCompleted = true;
    }
    if (widget.initialQuestions != null &&
        widget.initialQuestions!.isNotEmpty) {
      for (final QuizTakeQuestion q in widget.initialQuestions!) {
        final fields = QuizQuestionFields();
        fields.prompt.text = q.prompt;
        for (
          int i = 0;
          i < fields.options.length && i < q.options.length;
          i++
        ) {
          fields.options[i].text = q.options[i];
        }
        if (q.answerIndex >= 0 && q.answerIndex < fields.options.length) {
          fields.correctIndex = q.answerIndex;
        } else {
          fields.correctIndex = 0;
        }
        _questions.add(fields);
        _questionStepKeys.add(GlobalKey());
      }
      _detailsCompleted = true;
      _settingsCompleted = true;
      _questionSetupCompleted = true;
      _activeStep = 3;
    } else {
      _questions.add(QuizQuestionFields());
      _questionStepKeys.add(GlobalKey());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _timeLimitController.dispose();
    _pinController.dispose();
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }
}

class _QuizCreateScreenState extends _QuizCreateScreenStateBase
    with _QuizCreateScreenActions, _QuizCreateScreenBuild {}
