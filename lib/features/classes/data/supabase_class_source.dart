import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/college.dart';
import '../domain/class_source.dart';

/// Supabase implementation of [ClassSource].
///
/// Uses the new schema:
/// - `class_overview` view for denormalized class data
/// - `class_members` table for membership checks
/// - `class_resources` table for resources
/// - `class_notes` table for lecture notes
class SupabaseClassSource implements ClassSource {
  SupabaseClassSource(this._client);

  final SupabaseClient _client;
  final List<College> _colleges = <College>[];
  final Map<String, Set<String>> _classMemberIds = <String, Set<String>>{};

  /// Initialize and load data from Supabase.
  Future<void> load() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // Load from class_overview view
    final rows = await _client
        .from('class_overview')
        .select()
        .order('name', ascending: true);

    _colleges
      ..clear()
      ..addAll((rows as List).map((row) => _fromRow(row)));

    // Load user's class memberships
    await _loadUserMemberships(userId);
  }

  Future<void> _loadUserMemberships(String userId) async {
    final memberships = await _client
        .from('class_members')
        .select('class_id')
        .eq('user_id', userId);

    _classMemberIds.clear();
    for (final row in memberships as List) {
      final classId = row['class_id'] as String;
      _classMemberIds.putIfAbsent(classId, () => <String>{}).add(userId);
    }
  }

  @override
  List<College> userColleges(String handle) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    
    // Return colleges where user is a member
    return _colleges.where((c) {
      final classId = _getClassIdByCode(c.code);
      return classId != null && _classMemberIds.containsKey(classId);
    }).toList();
  }

  String? _getClassIdByCode(String code) {
    // We need to store class IDs - update the model to include it
    // For now, use a simple lookup from loaded data
    return null; // Will be fixed with updated model
  }

  @override
  List<College> allColleges() => List.unmodifiable(_colleges);

  @override
  College? findByCode(String code) {
    final normalized = code.toLowerCase();
    try {
      return _colleges.firstWhere((c) => c.code.toLowerCase() == normalized);
    } catch (_) {
      return null;
    }
  }

  @override
  List<College> searchPublicColleges(String query) {
    final lower = query.toLowerCase();
    return _colleges
        .where((c) =>
            c.name.toLowerCase().contains(lower) ||
            c.code.toLowerCase().contains(lower))
        .toList();
  }

  /// Join a class via invite code.
  Future<bool> joinClass(String inviteCode) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final result = await _client.rpc('join_class_via_invite', params: {
        'p_invite_code': inviteCode,
        'p_user_id': userId,
      });
      
      if (result == true) {
        await load(); // Refresh data
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Leave a class.
  Future<bool> leaveClass(String classId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    await _client
        .from('class_members')
        .delete()
        .eq('class_id', classId)
        .eq('user_id', userId);

    _classMemberIds[classId]?.remove(userId);
    return true;
  }

  /// Get class members.
  Future<List<Map<String, dynamic>>> getClassMembers(String classId) async {
    final rows = await _client
        .from('class_members')
        .select('user_id, role, joined_at, profiles(full_name, handle, avatar_url)')
        .eq('class_id', classId);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// Check if current user is a member of a class.
  Future<bool> isMember(String classId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final result = await _client
        .from('class_members')
        .select('id')
        .eq('class_id', classId)
        .eq('user_id', userId)
        .maybeSingle();

    return result != null;
  }

  /// Get user's role in a class.
  Future<String?> getUserRole(String classId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final result = await _client
        .from('class_members')
        .select('role')
        .eq('class_id', classId)
        .eq('user_id', userId)
        .maybeSingle();

    return result?['role'] as String?;
  }

  /// Load class resources.
  Future<List<CollegeResource>> loadResources(String classId) async {
    final rows = await _client
        .from('class_resources')
        .select()
        .eq('class_id', classId)
        .order('created_at', ascending: false);

    return (rows as List).map((row) => CollegeResource(
          title: row['title'] as String? ?? '',
          fileType: row['file_type'] as String? ?? '',
          size: row['file_size'] as String? ?? '',
        )).toList();
  }

  /// Load lecture notes for a class.
  Future<List<LectureNote>> loadLectureNotes(String classId) async {
    final rows = await _client
        .from('class_notes')
        .select('id, title, subtitle, estimated_minutes')
        .eq('class_id', classId)
        .order('created_at', ascending: false);

    return (rows as List).map((row) => LectureNote(
          title: row['title'] as String? ?? '',
          subtitle: row['subtitle'] as String?,
          size: row['estimated_minutes'] != null 
              ? '${row['estimated_minutes']} min' 
              : null,
        )).toList();
  }

  College _fromRow(Map<String, dynamic> row) {
    return College(
      name: row['name'] as String? ?? '',
      code: row['code'] as String? ?? '',
      facilitator: row['facilitator_name'] as String? ?? '',
      members: (row['member_count'] as num?)?.toInt() ?? 0,
      deliveryMode: row['delivery_mode'] as String? ?? '',
      upcomingExam: '', // Not in view, would need separate query
      resources: <CollegeResource>[], // Loaded separately via loadResources
      memberHandles: <String>{}, // No longer using JSONB handles
      lectureNotes: <LectureNote>[], // Loaded separately via loadLectureNotes
    );
  }
}

