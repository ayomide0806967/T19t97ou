import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/class_note.dart';

class ClassNotesStore {
  ClassNotesStore._();

  static final List<ClassNoteSummary> classNotes = <ClassNoteSummary>[];
  static final List<ClassNoteSummary> libraryNotes = <ClassNoteSummary>[];

  static VoidCallback? onChanged;

  static const String _storagePrefix = 'lecture_notes_';

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

  static Future<void> loadForCollege(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final base = '$_storagePrefix$code';
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

    classNotes
      ..clear()
      ..addAll(nextClassNotes);
    libraryNotes
      ..clear()
      ..addAll(nextLibraryNotes);
    onChanged?.call();
  }

  static Future<void> saveForCollege(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final base = '$_storagePrefix$code';
    final classJson = jsonEncode(classNotes.map(_summaryToJson).toList());
    final libraryJson = jsonEncode(libraryNotes.map(_summaryToJson).toList());
    await prefs.setString('${base}_class', classJson);
    await prefs.setString('${base}_library', libraryJson);
  }
}

