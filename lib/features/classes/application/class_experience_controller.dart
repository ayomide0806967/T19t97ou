import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/class_invites_source.dart';
import '../domain/class_memberships_source.dart';
import 'class_providers.dart';

/// Controller for high-level "class experience" flows such as joining a class
/// with an invite code. Keeps persistence logic out of widgets.
class ClassExperienceController extends Notifier<void> {
  @override
  void build() {}

  ClassInvitesSource get _invites => ref.read(classInvitesSourceProvider);
  ClassMembershipsSource get _memberships =>
      ref.read(classMembershipsSourceProvider);

  /// Attempts to join a class with an invite code.
  ///
  /// Returns the resolved class code on success, or `null` if the code
  /// could not be resolved.
  Future<String?> joinWithInviteCode({
    required String inviteCode,
    required String currentUserHandle,
  }) async {
    final resolved = await _invites.resolve(inviteCode);
    if (resolved == null) {
      return null;
    }

    final members = await _memberships.getMembersFor(resolved);
    members.add(currentUserHandle);
    await _memberships.saveMembersFor(resolved, members);
    return resolved;
  }
}

final classExperienceControllerProvider =
    NotifierProvider<ClassExperienceController, void>(
  ClassExperienceController.new,
);

