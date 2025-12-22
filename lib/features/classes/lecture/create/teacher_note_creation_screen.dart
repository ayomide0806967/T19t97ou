import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../models/class_note.dart';
import '../../../quiz/create/quiz_create_screen.dart';

part 'teacher_note_creation_screen_actions.dart';
part 'teacher_note_creation_screen_build.dart';
part 'teacher_note_creation_screen_steps.dart';

const int _maxWordsPerStep = 60;
const int _maxHeadingWords = 10;
const int _maxSubtitleWords = 5;

class TeacherNoteCreationScreen extends StatefulWidget {
  const TeacherNoteCreationScreen({
    super.key,
    required this.topic,
    required this.subtitle,
    this.attachQuizForNote = false,
    this.initialSections = const <ClassNoteSection>[],
    this.initialCreatedAt,
    this.initialCommentCount = 0,
  });

  final String topic;
  final String subtitle;
  final bool attachQuizForNote;
  final List<ClassNoteSection> initialSections;
  final DateTime? initialCreatedAt;
  final int initialCommentCount;

  @override
  State<TeacherNoteCreationScreen> createState() =>
      _TeacherNoteCreationScreenState();
}

abstract class _TeacherNoteCreationScreenStateBase
    extends State<TeacherNoteCreationScreen> {
  late List<ClassNoteSection> _sections;

  // Which step is currently being edited.
  // If null, we're adding a new step at the end.
  // If set to an index, we're editing that existing step.
  int? _editingIndex;

  // Controllers for editing
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _bulletsController = TextEditingController();

  final _scrollController = ScrollController();

  final Map<int, List<String>> _imagePathsByStep = <int, List<String>>{};
  String? _attachedQuizTitle;
}

class _TeacherNoteCreationScreenState
    extends _TeacherNoteCreationScreenStateBase
    with _TeacherNoteCreationActions, _TeacherNoteCreationBuild {
  @override
  void initState() {
    super.initState();
    _sections = List<ClassNoteSection>.from(widget.initialSections);
    for (int i = 0; i < _sections.length; i++) {
      if (_sections[i].imagePaths.isNotEmpty) {
        _imagePathsByStep[i] = List<String>.from(_sections[i].imagePaths);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _bulletsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildScreen(context);
  }
}
