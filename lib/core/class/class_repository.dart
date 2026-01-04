import 'package:flutter/foundation.dart';

/// Represents a class/course in the system.
@immutable
class ClassModel {
  const ClassModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.facilitatorId,
    this.facilitatorName,
    this.facilitatorAvatarUrl,
    this.deliveryMode = 'online',
    this.isPublic = true,
    this.memberCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final String? facilitatorId;
  final String? facilitatorName;
  final String? facilitatorAvatarUrl;
  final String deliveryMode;
  final bool isPublic;
  final int memberCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
}

/// Enum for class member roles.
enum ClassRole { student, admin, facilitator, ta }

/// A member of a class.
@immutable
class ClassMember {
  const ClassMember({
    required this.id,
    required this.classId,
    required this.userId,
    required this.userName,
    required this.userHandle,
    this.userAvatarUrl,
    required this.role,
    required this.joinedAt,
  });

  final String id;
  final String classId;
  final String userId;
  final String userName;
  final String userHandle;
  final String? userAvatarUrl;
  final ClassRole role;
  final DateTime joinedAt;
}

/// Request to create a new class.
@immutable
class CreateClassRequest {
  const CreateClassRequest({
    required this.code,
    required this.name,
    this.description,
    this.deliveryMode = 'online',
    this.isPublic = true,
  });

  final String code;
  final String name;
  final String? description;
  final String deliveryMode;
  final bool isPublic;
}

/// Domain-level contract for class operations.
abstract class ClassRepository {
  /// Watch classes the current user is a member of.
  Stream<List<ClassModel>> watchUserClasses();

  /// Get a class by ID.
  Future<ClassModel?> getClass(String classId);

  /// Get a class by code.
  Future<ClassModel?> getClassByCode(String code);

  /// Create a new class (current user becomes facilitator).
  Future<ClassModel> createClass(CreateClassRequest request);

  /// Update class details.
  Future<ClassModel> updateClass({
    required String classId,
    String? name,
    String? description,
    String? deliveryMode,
    bool? isPublic,
  });

  /// Archive a class (soft delete).
  Future<void> archiveClass(String classId);

  /// Join a class via invite code.
  Future<ClassModel> joinClass(String inviteCode);

  /// Leave a class.
  Future<void> leaveClass(String classId);

  /// Get members of a class.
  Future<List<ClassMember>> getMembers(String classId);

  /// Update a member's role (admin only).
  Future<void> updateMemberRole({
    required String classId,
    required String userId,
    required ClassRole newRole,
  });

  /// Remove a member from a class (admin only).
  Future<void> removeMember({
    required String classId,
    required String userId,
  });

  /// Create an invite code for a class.
  Future<String> createInviteCode({
    required String classId,
    DateTime? expiresAt,
    int? maxUses,
  });
}
