import 'dart:async';

import 'note_repository.dart';

/// Local in-memory implementation of [NoteRepository].
///
/// Intended for offline/demo usage only. Data is not persisted.
class LocalNoteRepository implements NoteRepository {
  final Map<String, Note> _notesById = <String, Note>{};
  final Map<String, List<NoteSection>> _sectionsByNoteId =
      <String, List<NoteSection>>{};
  final Map<String, List<Note>> _notesByClassId =
      <String, List<Note>>{};

  final Map<String, StreamController<List<Note>>> _classNoteControllers =
      <String, StreamController<List<Note>>>{};

  @override
  Stream<List<Note>> watchClassNotes(String classId) {
    _classNoteControllers.putIfAbsent(
      classId,
      () => StreamController<List<Note>>.broadcast(),
    );
    _emitClassNotes(classId);
    return _classNoteControllers[classId]!.stream;
  }

  @override
  Future<Note?> getNote(String noteId) async => _notesById[noteId];

  @override
  Future<List<NoteSection>> getSections(String noteId) async {
    return List<NoteSection>.unmodifiable(
      _sectionsByNoteId[noteId] ?? <NoteSection>[],
    );
  }

  @override
  Future<Note> createNote(CreateNoteRequest request) async {
    final now = DateTime.now();
    final id = 'local_note_${now.microsecondsSinceEpoch}';
    final note = Note(
      id: id,
      classId: request.classId,
      authorId: 'local_user',
      topicId: request.topicId,
      title: request.title,
      description: request.description,
      coverImageUrl: request.coverImageUrl,
      authorName: 'Local User',
      authorAvatarUrl: null,
      isPublished: false,
      sectionCount: request.sections.length,
      createdAt: now,
      updatedAt: null,
      publishedAt: null,
    );
    _notesById[id] = note;
    final classList =
        _notesByClassId.putIfAbsent(request.classId, () => <Note>[]);
    classList.add(note);

    final sections = <NoteSection>[];
    for (var i = 0; i < request.sections.length; i++) {
      final s = request.sections[i];
      sections.add(
        NoteSection(
          id: 'local_note_section_${now.microsecondsSinceEpoch}_$i',
          noteId: id,
          orderIndex: i,
          content: s.content,
          heading: s.heading,
          mediaType: s.mediaType,
          mediaUrls: s.mediaUrls,
        ),
      );
    }
    _sectionsByNoteId[id] = sections;
    _emitClassNotes(request.classId);
    return note;
  }

  @override
  Future<Note> updateNote({
    required String noteId,
    String? title,
    String? description,
    String? coverImageUrl,
  }) async {
    final existing = _notesById[noteId];
    if (existing == null) {
      throw StateError('Note not found');
    }
    final updated = Note(
      id: existing.id,
      classId: existing.classId,
      authorId: existing.authorId,
      topicId: existing.topicId,
      title: title ?? existing.title,
      description: description ?? existing.description,
      coverImageUrl: coverImageUrl ?? existing.coverImageUrl,
      authorName: existing.authorName,
      authorAvatarUrl: existing.authorAvatarUrl,
      isPublished: existing.isPublished,
      sectionCount: existing.sectionCount,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      publishedAt: existing.publishedAt,
    );
    _notesById[noteId] = updated;
    _updateClassNoteList(updated);
    return updated;
  }

  @override
  Future<NoteSection> addSection({
    required String noteId,
    required String content,
    String? heading,
    String? mediaType,
    List<String> mediaUrls = const <String>[],
  }) async {
    final list = _sectionsByNoteId.putIfAbsent(
      noteId,
      () => <NoteSection>[],
    );
    final now = DateTime.now();
    final section = NoteSection(
      id: 'local_note_section_${now.microsecondsSinceEpoch}_${list.length}',
      noteId: noteId,
      orderIndex: list.length,
      content: content,
      heading: heading,
      mediaType: mediaType,
      mediaUrls: mediaUrls,
    );
    list.add(section);
    final note = _notesById[noteId];
    if (note != null) {
      _notesById[noteId] = Note(
        id: note.id,
        classId: note.classId,
        authorId: note.authorId,
        topicId: note.topicId,
        title: note.title,
        description: note.description,
        coverImageUrl: note.coverImageUrl,
        authorName: note.authorName,
        authorAvatarUrl: note.authorAvatarUrl,
        isPublished: note.isPublished,
        sectionCount: list.length,
        createdAt: note.createdAt,
        updatedAt: DateTime.now(),
        publishedAt: note.publishedAt,
      );
      _updateClassNoteList(_notesById[noteId]!);
    }
    return section;
  }

  @override
  Future<NoteSection> updateSection({
    required String sectionId,
    String? content,
    String? heading,
    String? mediaType,
    List<String>? mediaUrls,
  }) async {
    for (final entry in _sectionsByNoteId.entries) {
      final list = entry.value;
      final index = list.indexWhere((s) => s.id == sectionId);
      if (index != -1) {
        final existing = list[index];
        final updated = NoteSection(
          id: existing.id,
          noteId: existing.noteId,
          orderIndex: existing.orderIndex,
          content: content ?? existing.content,
          heading: heading ?? existing.heading,
          mediaType: mediaType ?? existing.mediaType,
          mediaUrls: mediaUrls ?? existing.mediaUrls,
        );
        list[index] = updated;
        return updated;
      }
    }
    throw StateError('Note section not found');
  }

  @override
  Future<void> deleteSection(String sectionId) async {
    for (final entry in _sectionsByNoteId.entries) {
      final list = entry.value;
      final before = list.length;
      list.removeWhere((s) => s.id == sectionId);
      final removed = list.length != before;
      if (removed) {
        return;
      }
    }
  }

  @override
  Future<void> reorderSections(String noteId, List<String> sectionIds) async {
    final list = _sectionsByNoteId[noteId];
    if (list == null) return;
    final byId = {for (final s in list) s.id: s};
    final reordered = <NoteSection>[];
    for (var i = 0; i < sectionIds.length; i++) {
      final id = sectionIds[i];
      final existing = byId[id];
      if (existing != null) {
        reordered.add(
          NoteSection(
            id: existing.id,
            noteId: existing.noteId,
            orderIndex: i,
            content: existing.content,
            heading: existing.heading,
            mediaType: existing.mediaType,
            mediaUrls: existing.mediaUrls,
          ),
        );
      }
    }
    _sectionsByNoteId[noteId] = reordered;
  }

  @override
  Future<Note> publishNote(String noteId) async {
    final existing = _notesById[noteId];
    if (existing == null) {
      throw StateError('Note not found');
    }
    final updated = Note(
      id: existing.id,
      classId: existing.classId,
      authorId: existing.authorId,
      topicId: existing.topicId,
      title: existing.title,
      description: existing.description,
      coverImageUrl: existing.coverImageUrl,
      authorName: existing.authorName,
      authorAvatarUrl: existing.authorAvatarUrl,
      isPublished: true,
      sectionCount: existing.sectionCount,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      publishedAt: DateTime.now(),
    );
    _notesById[noteId] = updated;
    _updateClassNoteList(updated);
    return updated;
  }

  @override
  Future<void> deleteNote(String noteId) async {
    final note = _notesById.remove(noteId);
    if (note != null) {
      final classList = _notesByClassId[note.classId];
      classList?.removeWhere((n) => n.id == noteId);
      _emitClassNotes(note.classId);
    }
    _sectionsByNoteId.remove(noteId);
  }

  void _emitClassNotes(String classId) {
    final controller = _classNoteControllers[classId];
    if (controller == null || controller.isClosed) return;
    controller.add(
      List<Note>.unmodifiable(_notesByClassId[classId] ?? <Note>[]),
    );
  }

  void _updateClassNoteList(Note note) {
    final classList =
        _notesByClassId.putIfAbsent(note.classId, () => <Note>[]);
    final index = classList.indexWhere((n) => n.id == note.id);
    if (index == -1) {
      classList.add(note);
    } else {
      classList[index] = note;
    }
    _emitClassNotes(note.classId);
  }

  void dispose() {
    for (final controller in _classNoteControllers.values) {
      controller.close();
    }
  }
}
