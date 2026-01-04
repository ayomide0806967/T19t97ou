import 'package:flutter/foundation.dart';

/// A class note (lecture material).
@immutable
class Note {
  const Note({
    required this.id,
    required this.classId,
    required this.authorId,
    this.topicId,
    required this.title,
    this.description,
    this.coverImageUrl,
    this.authorName,
    this.authorAvatarUrl,
    this.isPublished = false,
    this.sectionCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.publishedAt,
  });

  final String id;
  final String classId;
  final String authorId;
  final String? topicId;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final String? authorName;
  final String? authorAvatarUrl;
  final bool isPublished;
  final int sectionCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;
}

/// A section within a note.
@immutable
class NoteSection {
  const NoteSection({
    required this.id,
    required this.noteId,
    required this.orderIndex,
    required this.content,
    this.heading,
    this.mediaType,
    this.mediaUrls = const [],
  });

  final String id;
  final String noteId;
  final int orderIndex;
  final String content;
  final String? heading;
  final String? mediaType;
  final List<String> mediaUrls;
}

/// Request to create a new note.
@immutable
class CreateNoteRequest {
  const CreateNoteRequest({
    required this.classId,
    required this.title,
    this.topicId,
    this.description,
    this.coverImageUrl,
    this.sections = const [],
  });

  final String classId;
  final String title;
  final String? topicId;
  final String? description;
  final String? coverImageUrl;
  final List<CreateNoteSectionRequest> sections;
}

/// Request to create a note section.
@immutable
class CreateNoteSectionRequest {
  const CreateNoteSectionRequest({
    required this.content,
    this.heading,
    this.mediaType,
    this.mediaUrls = const [],
  });

  final String content;
  final String? heading;
  final String? mediaType;
  final List<String> mediaUrls;
}

/// Domain-level contract for note operations.
abstract class NoteRepository {
  /// Watch notes for a class.
  Stream<List<Note>> watchClassNotes(String classId);

  /// Get a note by ID.
  Future<Note?> getNote(String noteId);

  /// Get sections for a note.
  Future<List<NoteSection>> getSections(String noteId);

  /// Create a new note with sections.
  Future<Note> createNote(CreateNoteRequest request);

  /// Update note metadata.
  Future<Note> updateNote({
    required String noteId,
    String? title,
    String? description,
    String? coverImageUrl,
  });

  /// Add a section to a note.
  Future<NoteSection> addSection({
    required String noteId,
    required String content,
    String? heading,
    String? mediaType,
    List<String> mediaUrls,
  });

  /// Update a section.
  Future<NoteSection> updateSection({
    required String sectionId,
    String? content,
    String? heading,
    String? mediaType,
    List<String>? mediaUrls,
  });

  /// Delete a section.
  Future<void> deleteSection(String sectionId);

  /// Reorder sections.
  Future<void> reorderSections(String noteId, List<String> sectionIds);

  /// Publish a note.
  Future<Note> publishNote(String noteId);

  /// Delete a note.
  Future<void> deleteNote(String noteId);
}
