import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../note/note_repository.dart';

/// Supabase implementation of [NoteRepository].
///
/// Uses:
/// - `class_notes` table for note data
/// - `note_sections` for sections
/// - `section_media` for media attachments
class SupabaseNoteRepository implements NoteRepository {
  SupabaseNoteRepository(this._client);

  final SupabaseClient _client;
  final Map<String, StreamController<List<Note>>> _controllers = {};
  final Map<String, RealtimeChannel> _channels = {};

  String? get _userId => _client.auth.currentUser?.id;

  @override
  Stream<List<Note>> watchClassNotes(String classId) {
    if (!_controllers.containsKey(classId)) {
      _controllers[classId] = StreamController<List<Note>>.broadcast(
        onListen: () => _subscribeToNotes(classId),
        onCancel: () => _unsubscribeFromNotes(classId),
      );
      _loadClassNotes(classId);
    }
    return _controllers[classId]!.stream;
  }

  Future<void> _loadClassNotes(String classId) async {
    final rows = await _client
        .from('class_notes')
        .select('''
          id, class_id, author_id, topic_id, title, subtitle, visibility,
          created_at, updated_at, published_at,
          profiles!inner(full_name, avatar_url)
        ''')
        .eq('class_id', classId)
        .order('created_at', ascending: false);

    final notes = (rows as List).map((r) => _noteFromRow(r)).toList();
    _controllers[classId]?.add(notes);
  }

  void _subscribeToNotes(String classId) {
    _channels[classId] = _client
        .channel('notes:$classId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'class_notes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'class_id',
            value: classId,
          ),
          callback: (_) => _loadClassNotes(classId),
        )
        .subscribe();
  }

  void _unsubscribeFromNotes(String classId) {
    _channels[classId]?.unsubscribe();
    _channels.remove(classId);
  }

  @override
  Future<Note?> getNote(String noteId) async {
    final row = await _client
        .from('class_notes')
        .select('''
          id, class_id, author_id, topic_id, title, subtitle, visibility,
          created_at, updated_at, published_at,
          profiles!inner(full_name, avatar_url)
        ''')
        .eq('id', noteId)
        .maybeSingle();

    if (row == null) return null;
    return _noteFromRow(row);
  }

  @override
  Future<List<NoteSection>> getSections(String noteId) async {
    final rows = await _client
        .from('note_sections')
        .select('id, note_id, order_index, title, content_type, bullets, paragraph_text')
        .eq('note_id', noteId)
        .order('order_index', ascending: true);

    return (rows as List).map((r) => _sectionFromRow(r)).toList();
  }

  @override
  Future<Note> createNote(CreateNoteRequest request) async {
    final userId = _userId;
    if (userId == null) throw StateError('Not signed in');

    final row = await _client.from('class_notes').insert({
      'class_id': request.classId,
      'author_id': userId,
      'topic_id': request.topicId,
      'title': request.title,
      'subtitle': request.description,
    }).select('''
      id, class_id, author_id, topic_id, title, subtitle, visibility,
      created_at, updated_at, published_at,
      profiles!inner(full_name, avatar_url)
    ''').single();

    final note = _noteFromRow(row);

    // Add sections
    for (var i = 0; i < request.sections.length; i++) {
      final section = request.sections[i];
      await _client.from('note_sections').insert({
        'note_id': note.id,
        'order_index': i,
        'title': section.heading,
        'paragraph_text': section.content,
        'content_type': 'paragraph',
      });
    }

    return note;
  }

  @override
  Future<Note> updateNote({
    required String noteId,
    String? title,
    String? description,
    String? coverImageUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['subtitle'] = description;

    final row = await _client
        .from('class_notes')
        .update(updates)
        .eq('id', noteId)
        .select('''
          id, class_id, author_id, topic_id, title, subtitle, visibility,
          created_at, updated_at, published_at,
          profiles!inner(full_name, avatar_url)
        ''')
        .single();

    return _noteFromRow(row);
  }

  @override
  Future<NoteSection> addSection({
    required String noteId,
    required String content,
    String? heading,
    String? mediaType,
    List<String>? mediaUrls,
  }) async {
    // Get current max order index
    final existing = await _client
        .from('note_sections')
        .select('order_index')
        .eq('note_id', noteId)
        .order('order_index', ascending: false)
        .limit(1);

    final nextIndex = existing.isEmpty ? 0 : (existing[0]['order_index'] as int) + 1;

    final row = await _client.from('note_sections').insert({
      'note_id': noteId,
      'title': heading,
      'paragraph_text': content,
      'content_type': 'paragraph',
      'order_index': nextIndex,
    }).select().single();

    return _sectionFromRow(row);
  }

  @override
  Future<NoteSection> updateSection({
    required String sectionId,
    String? content,
    String? heading,
    String? mediaType,
    List<String>? mediaUrls,
  }) async {
    final updates = <String, dynamic>{};
    if (content != null) updates['paragraph_text'] = content;
    if (heading != null) updates['title'] = heading;

    final row = await _client
        .from('note_sections')
        .update(updates)
        .eq('id', sectionId)
        .select()
        .single();

    return _sectionFromRow(row);
  }

  @override
  Future<void> deleteSection(String sectionId) async {
    await _client.from('note_sections').delete().eq('id', sectionId);
  }

  @override
  Future<void> reorderSections(String noteId, List<String> sectionIds) async {
    for (var i = 0; i < sectionIds.length; i++) {
      await _client
          .from('note_sections')
          .update({'order_index': i})
          .eq('id', sectionIds[i]);
    }
  }

  @override
  Future<Note> publishNote(String noteId) async {
    final row = await _client.from('class_notes').update({
      'published_at': DateTime.now().toIso8601String(),
      'visibility': 'public',
    }).eq('id', noteId).select('''
      id, class_id, author_id, topic_id, title, subtitle, visibility,
      created_at, updated_at, published_at,
      profiles!inner(full_name, avatar_url)
    ''').single();

    return _noteFromRow(row);
  }

  @override
  Future<void> deleteNote(String noteId) async {
    await _client.from('class_notes').delete().eq('id', noteId);
  }

  Note _noteFromRow(Map<String, dynamic> row) {
    final profile = row['profiles'] as Map<String, dynamic>?;
    return Note(
      id: row['id'] as String,
      classId: row['class_id'] as String? ?? '',
      authorId: row['author_id'] as String,
      topicId: row['topic_id'] as String?,
      title: row['title'] as String,
      description: row['subtitle'] as String?,
      authorName: profile?['full_name'] as String?,
      authorAvatarUrl: profile?['avatar_url'] as String?,
      isPublished: row['published_at'] != null,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
      publishedAt: row['published_at'] != null
          ? DateTime.parse(row['published_at'] as String)
          : null,
    );
  }

  NoteSection _sectionFromRow(Map<String, dynamic> row) {
    return NoteSection(
      id: row['id'] as String,
      noteId: row['note_id'] as String,
      orderIndex: row['order_index'] as int? ?? 0,
      content: row['paragraph_text'] as String? ?? '',
      heading: row['title'] as String?,
    );
  }

  void dispose() {
    for (final channel in _channels.values) {
      channel.unsubscribe();
    }
    for (final controller in _controllers.values) {
      controller.close();
    }
    _channels.clear();
    _controllers.clear();
  }
}
