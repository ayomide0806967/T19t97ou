import 'dart:async';

import 'class_repository.dart';

/// Local in-memory implementation of [ClassRepository].
///
/// This is suitable for offline/demo mode; data exists only in memory.
class LocalClassRepository implements ClassRepository {
  final List<ClassModel> _classes = <ClassModel>[];
  final Map<String, List<ClassMember>> _membersByClass =
      <String, List<ClassMember>>{};

  final StreamController<List<ClassModel>> _classesController =
      StreamController<List<ClassModel>>.broadcast();

  @override
  Stream<List<ClassModel>> watchUserClasses() =>
      _classesController.stream;

  @override
  Future<List<ClassModel>> getUserClasses() async =>
      List<ClassModel>.unmodifiable(_classes);

  @override
  Future<ClassModel?> getClass(String classId) async {
    try {
      return _classes.firstWhere((c) => c.id == classId);
    } on StateError {
      return null;
    }
  }

  @override
  Future<ClassModel?> getClassByCode(String code) async {
    try {
      return _classes.firstWhere(
        (c) => c.code.toLowerCase() == code.toLowerCase(),
      );
    } on StateError {
      return null;
    }
  }

  @override
  Future<ClassModel> createClass(CreateClassRequest request) async {
    final now = DateTime.now();
    final id = 'local_class_${now.microsecondsSinceEpoch}';
    final model = ClassModel(
      id: id,
      code: request.code,
      name: request.name,
      description: request.description,
      createdAt: now,
      isPublic: request.isPublic,
      deliveryMode: request.deliveryMode,
      memberCount: 0,
    );
    _classes.add(model);
    _emitClasses();
    return model;
  }

  @override
  Future<ClassModel> updateClass({
    required String classId,
    String? name,
    String? description,
    String? deliveryMode,
    bool? isPublic,
  }) async {
    final index = _classes.indexWhere((c) => c.id == classId);
    if (index == -1) {
      throw StateError('Class not found');
    }
    final existing = _classes[index];
    final updated = ClassModel(
      id: existing.id,
      code: existing.code,
      name: name ?? existing.name,
      description: description ?? existing.description,
      facilitatorId: existing.facilitatorId,
      facilitatorName: existing.facilitatorName,
      facilitatorAvatarUrl: existing.facilitatorAvatarUrl,
      deliveryMode: deliveryMode ?? existing.deliveryMode,
      isPublic: isPublic ?? existing.isPublic,
      memberCount: existing.memberCount,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    _classes[index] = updated;
    _emitClasses();
    return updated;
  }

  @override
  Future<void> archiveClass(String classId) async {
    // Local mode: treat archive as delete.
    await deleteClass(classId);
  }

  @override
  Future<void> deleteClass(String classId) async {
    _classes.removeWhere((c) => c.id == classId);
    _membersByClass.remove(classId);
    _emitClasses();
  }

  @override
  Future<List<ClassMember>> getMembers(String classId) async {
    return List<ClassMember>.unmodifiable(
      _membersByClass[classId] ?? <ClassMember>[],
    );
  }

  @override
  Future<ClassModel> joinClass(String inviteCode) async {
    // In local mode, invite codes are of the form 'LOCAL-<classId>'.
    final parts = inviteCode.split('LOCAL-');
    if (parts.length == 2 && parts[1].isNotEmpty) {
      final classId = parts[1];
      final classModel = await getClass(classId);
      if (classModel != null) {
        return classModel;
      }
    }
    throw StateError('Class not found for invite');
  }

  @override
  Future<void> leaveClass(String classId) async {
    _membersByClass.remove(classId);
    _emitClasses();
  }

  @override
  Future<void> updateMemberRole({
    required String classId,
    required String userId,
    required ClassRole newRole,
  }) async {
    final members = _membersByClass[classId];
    if (members == null) return;
    final index = members.indexWhere((m) => m.userId == userId);
    if (index == -1) return;
    final existing = members[index];
    members[index] = ClassMember(
      id: existing.id,
      classId: existing.classId,
      userId: existing.userId,
      userName: existing.userName,
      userHandle: existing.userHandle,
      userAvatarUrl: existing.userAvatarUrl,
      role: newRole,
      joinedAt: existing.joinedAt,
    );
  }

  @override
  Future<void> removeMember({
    required String classId,
    required String userId,
  }) async {
    final members = _membersByClass[classId];
    members?.removeWhere((m) => m.userId == userId);
  }

  @override
  Future<String> createInviteCode({
    required String classId,
    DateTime? expiresAt,
    int? maxUses,
  }) async {
    // Local mode: generate a stable, non-functional code.
    return 'LOCAL-$classId';
  }

  void _emitClasses() {
    if (_classesController.isClosed) return;
    _classesController.add(List<ClassModel>.unmodifiable(_classes));
  }

  void dispose() {
    _classesController.close();
  }
}
