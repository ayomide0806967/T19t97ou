import 'dart:async';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../class/class_repository.dart';

/// Supabase implementation of [ClassRepository].
///
/// Uses:
/// - `classes` table for class data
/// - `class_members` for membership
/// - `class_invites` for invite codes
/// - `join_class_via_invite()` DB function
class SupabaseClassRepository implements ClassRepository {
  SupabaseClassRepository(this._client);

  final SupabaseClient _client;
  final _random = Random();

  StreamController<List<ClassModel>>? _classesController;
  RealtimeChannel? _classesChannel;

  String? get _userId => _client.auth.currentUser?.id;

  @override
  Stream<List<ClassModel>> watchUserClasses() {
    _classesController ??= StreamController<List<ClassModel>>.broadcast(
      onListen: () => _subscribeToUserClasses(),
      onCancel: () => _unsubscribeFromClasses(),
    );
    // Initial load
    _loadUserClasses();
    return _classesController!.stream;
  }

  Future<void> _loadUserClasses() async {
    final userId = _userId;
    if (userId == null) return;

    // Get class IDs user is a member of
    final memberships = await _client
        .from('class_members')
        .select('class_id')
        .eq('user_id', userId);

    if ((memberships as List).isEmpty) {
      _classesController?.add([]);
      return;
    }

    final classIds = memberships.map((m) => m['class_id'] as String).toList();

    final rows = await _client
        .from('classes')
        .select('''
          id, code, name, description, facilitator_id, delivery_mode, 
          is_public, created_at, updated_at,
          profiles!classes_facilitator_id_fkey(full_name, avatar_url)
        ''')
        .inFilter('id', classIds)
        .isFilter('archived_at', null)
        .order('created_at', ascending: false);

    final classes = (rows as List).map((r) => _classFromRow(r)).toList();
    _classesController?.add(classes);
  }

  void _subscribeToUserClasses() {
    final userId = _userId;
    if (userId == null) return;

    _classesChannel = _client
        .channel('user_classes:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'class_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => _loadUserClasses(),
        )
        .subscribe();
  }

  void _unsubscribeFromClasses() {
    _classesChannel?.unsubscribe();
    _classesChannel = null;
  }

  @override
  Future<ClassModel?> getClass(String classId) async {
    final row = await _client
        .from('classes')
        .select('''
          id, code, name, description, facilitator_id, delivery_mode, 
          is_public, created_at, updated_at,
          profiles!classes_facilitator_id_fkey(full_name, avatar_url)
        ''')
        .eq('id', classId)
        .maybeSingle();

    if (row == null) return null;
    return _classFromRow(row);
  }

  @override
  Future<ClassModel?> getClassByCode(String code) async {
    final row = await _client
        .from('classes')
        .select('''
          id, code, name, description, facilitator_id, delivery_mode, 
          is_public, created_at, updated_at,
          profiles!classes_facilitator_id_fkey(full_name, avatar_url)
        ''')
        .eq('code', code.toUpperCase())
        .maybeSingle();

    if (row == null) return null;
    return _classFromRow(row);
  }

  @override
  Future<ClassModel> createClass(CreateClassRequest request) async {
    final userId = _userId;
    if (userId == null) throw StateError('Not signed in');

    final row = await _client.from('classes').insert({
      'code': request.code.toUpperCase(),
      'name': request.name,
      'description': request.description,
      'facilitator_id': userId,
      'delivery_mode': request.deliveryMode,
      'is_public': request.isPublic,
    }).select('''
      id, code, name, description, facilitator_id, delivery_mode, 
      is_public, created_at, updated_at,
      profiles!classes_facilitator_id_fkey(full_name, avatar_url)
    ''').single();

    // Add creator as facilitator member
    await _client.from('class_members').insert({
      'class_id': row['id'],
      'user_id': userId,
      'role': 'facilitator',
    });

    return _classFromRow(row);
  }

  @override
  Future<ClassModel> updateClass({
    required String classId,
    String? name,
    String? description,
    String? deliveryMode,
    bool? isPublic,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (deliveryMode != null) updates['delivery_mode'] = deliveryMode;
    if (isPublic != null) updates['is_public'] = isPublic;

    final row = await _client
        .from('classes')
        .update(updates)
        .eq('id', classId)
        .select('''
          id, code, name, description, facilitator_id, delivery_mode, 
          is_public, created_at, updated_at,
          profiles!classes_facilitator_id_fkey(full_name, avatar_url)
        ''')
        .single();

    return _classFromRow(row);
  }

  @override
  Future<void> archiveClass(String classId) async {
    await _client
        .from('classes')
        .update({'archived_at': DateTime.now().toIso8601String()})
        .eq('id', classId);
  }

  @override
  Future<ClassModel> joinClass(String inviteCode) async {
    // Use the DB function to join
    final classId = await _client.rpc('join_class_via_invite', params: {
      'p_invite_code': inviteCode,
    });

    final classModel = await getClass(classId as String);
    if (classModel == null) {
      throw StateError('Failed to load class after joining');
    }
    return classModel;
  }

  @override
  Future<void> leaveClass(String classId) async {
    final userId = _userId;
    if (userId == null) return;

    await _client
        .from('class_members')
        .delete()
        .eq('class_id', classId)
        .eq('user_id', userId);
  }

  @override
  Future<List<ClassMember>> getMembers(String classId) async {
    final rows = await _client
        .from('class_members')
        .select('''
          id, class_id, user_id, role, joined_at,
          profiles!inner(full_name, handle, avatar_url)
        ''')
        .eq('class_id', classId)
        .order('joined_at', ascending: true);

    return (rows as List).map((r) => _memberFromRow(r)).toList();
  }

  @override
  Future<void> updateMemberRole({
    required String classId,
    required String userId,
    required ClassRole newRole,
  }) async {
    await _client
        .from('class_members')
        .update({'role': newRole.name})
        .eq('class_id', classId)
        .eq('user_id', userId);
  }

  @override
  Future<void> removeMember({
    required String classId,
    required String userId,
  }) async {
    await _client
        .from('class_members')
        .delete()
        .eq('class_id', classId)
        .eq('user_id', userId);
  }

  @override
  Future<String> createInviteCode({
    required String classId,
    DateTime? expiresAt,
    int? maxUses,
  }) async {
    final classData = await getClass(classId);
    if (classData == null) throw StateError('Class not found');

    final inviteCode = _generateInviteCode();

    await _client.from('class_invites').insert({
      'class_code': classData.code,
      'invite_code': inviteCode,
      'created_by': _userId,
      'expires_at': expiresAt?.toIso8601String(),
      'max_uses': maxUses,
    });

    return inviteCode;
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(8, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  ClassModel _classFromRow(Map<String, dynamic> row) {
    final facilitator = row['profiles'] as Map<String, dynamic>?;
    return ClassModel(
      id: row['id'] as String,
      code: row['code'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      facilitatorId: row['facilitator_id'] as String?,
      facilitatorName: facilitator?['full_name'] as String?,
      facilitatorAvatarUrl: facilitator?['avatar_url'] as String?,
      deliveryMode: row['delivery_mode'] as String? ?? 'online',
      isPublic: row['is_public'] as bool? ?? true,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }

  ClassMember _memberFromRow(Map<String, dynamic> row) {
    final profile = row['profiles'] as Map<String, dynamic>;
    return ClassMember(
      id: row['id'] as String,
      classId: row['class_id'] as String,
      userId: row['user_id'] as String,
      userName: profile['full_name'] as String? ?? '',
      userHandle: profile['handle'] as String? ?? '',
      userAvatarUrl: profile['avatar_url'] as String?,
      role: ClassRole.values.firstWhere(
        (r) => r.name == row['role'],
        orElse: () => ClassRole.student,
      ),
      joinedAt: DateTime.parse(row['joined_at'] as String),
    );
  }

  void dispose() {
    _classesChannel?.unsubscribe();
    _classesController?.close();
  }
}
