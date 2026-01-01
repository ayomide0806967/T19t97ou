import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/class_note.dart';

part 'class_notes_shelf_controller.g.dart';

class ClassNotesShelfState {
  const ClassNotesShelfState({
    this.classNotes = const <ClassNoteSummary>[],
    this.libraryNotes = const <ClassNoteSummary>[],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<ClassNoteSummary> classNotes;
  final List<ClassNoteSummary> libraryNotes;
  final bool isLoading;
  final String? errorMessage;

  ClassNotesShelfState copyWith({
    List<ClassNoteSummary>? classNotes,
    List<ClassNoteSummary>? libraryNotes,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ClassNotesShelfState(
      classNotes: classNotes ?? this.classNotes,
      libraryNotes: libraryNotes ?? this.libraryNotes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

@riverpod
class ClassNotesShelfController extends _$ClassNotesShelfController {
  static const String _storagePrefix = 'lecture_notes_';

  @override
  ClassNotesShelfState build(String classCode) {
    return const ClassNotesShelfState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final base = '$_storagePrefix$classCode';
      final rawClass = prefs.getString('${base}_class');
      final rawLibrary = prefs.getString('${base}_library');

      final List<ClassNoteSummary> nextClassNotes;
      final List<ClassNoteSummary> nextLibraryNotes;

      if (rawClass != null) {
        nextClassNotes = (jsonDecode(rawClass) as List)
            .cast<Map<String, dynamic>>()
            .map(_summaryFromJson)
            .toList();
      } else {
        nextClassNotes = <ClassNoteSummary>[];
      }

      if (rawLibrary != null) {
        nextLibraryNotes = (jsonDecode(rawLibrary) as List)
            .cast<Map<String, dynamic>>()
            .map(_summaryFromJson)
            .toList();
      } else {
        nextLibraryNotes = <ClassNoteSummary>[];
      }

      state = state.copyWith(
        classNotes: nextClassNotes,
        libraryNotes: nextLibraryNotes,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final base = '$_storagePrefix$classCode';
    final classJson =
        jsonEncode(state.classNotes.map(_summaryToJson).toList());
    final libraryJson =
        jsonEncode(state.libraryNotes.map(_summaryToJson).toList());
    await prefs.setString('${base}_class', classJson);
    await prefs.setString('${base}_library', libraryJson);
  }

  Future<void> addClassNote(ClassNoteSummary note) async {
    final nextNotes = <ClassNoteSummary>[note, ...state.classNotes];
    state = state.copyWith(classNotes: nextNotes);
    await _persist();
  }

  Future<void> updateClassNote(
    ClassNoteSummary original,
    ClassNoteSummary updated,
  ) async {
    final list = <ClassNoteSummary>[...state.classNotes];
    final index = list.indexOf(original);
    if (index == -1) return;
    list[index] = updated;
    state = state.copyWith(classNotes: list);
    await _persist();
  }

  Future<void> moveToLibrary(ClassNoteSummary note) async {
    final nextClass = <ClassNoteSummary>[...state.classNotes]..remove(note);
    final nextLibrary = <ClassNoteSummary>[note, ...state.libraryNotes];
    state = state.copyWith(
      classNotes: nextClass,
      libraryNotes: nextLibrary,
    );
    await _persist();
  }

  Future<void> deleteClassNote(ClassNoteSummary note) async {
    final nextClass = <ClassNoteSummary>[...state.classNotes]..remove(note);
    state = state.copyWith(classNotes: nextClass);
    await _persist();
  }

  static Map<String, dynamic> _sectionToJson(ClassNoteSection s) => {
        'title': s.title,
        'subtitle': s.subtitle,
        'bullets': s.bullets,
        'imagePaths': s.imagePaths,
      };

  static ClassNoteSection _sectionFromJson(Map<String, dynamic> json) =>
      ClassNoteSection(
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        bullets: (json['bullets'] as List?)?.cast<String>() ?? const <String>[],
        imagePaths:
            (json['imagePaths'] as List?)?.cast<String>() ?? const <String>[],
      );

  static Map<String, dynamic> _summaryToJson(ClassNoteSummary s) => {
        'title': s.title,
        'subtitle': s.subtitle,
        'steps': s.steps,
        'estimatedMinutes': s.estimatedMinutes,
        'createdAt': s.createdAt.toIso8601String(),
        'commentCount': s.commentCount,
        'sections': s.sections.map(_sectionToJson).toList(),
        'attachedQuizTitle': s.attachedQuizTitle,
      };

  static ClassNoteSummary _summaryFromJson(Map<String, dynamic> json) =>
      ClassNoteSummary(
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        steps: (json['steps'] as num).toInt(),
        estimatedMinutes: (json['estimatedMinutes'] as num).toInt(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
        sections: (json['sections'] as List?)
                ?.map((e) => _sectionFromJson(e as Map<String, dynamic>))
                .toList() ??
            const <ClassNoteSection>[],
        attachedQuizTitle: json['attachedQuizTitle'] as String?,
      );
}
