import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/class_memberships_source.dart';
import '../domain/class_roles_source.dart';
import 'class_providers.dart';
import 'class_room_state.dart';

part 'class_room_controller.g.dart';

/// Controller responsible for class membership/admin state for a single class.
///
/// This centralizes logic that was previously scattered across widget state
/// in the iOS messages "College" screen, so UI can stay focused on rendering.
@riverpod
class ClassRoomController extends _$ClassRoomController {
  @override
  ClassRoomState build(String classCode) {
    return ClassRoomState(
      classCode: classCode,
      members: <String>{},
      admins: <String>{},
      isLoading: false,
    );
  }

  ClassMembershipsSource get _memberships =>
      ref.read(classMembershipsSourceProvider);
  ClassRolesSource get _roles => ref.read(classRolesSourceProvider);

  /// Bootstrap admin and membership data for this class code.
  ///
  /// - If no admins are stored yet, the current user becomes the first admin.
  /// - If no members are stored yet, we seed from [initialMemberHandles] and
  ///   ensure [currentUserHandle] is included.
  Future<void> bootstrap({
    required Set<String> initialMemberHandles,
    required String currentUserHandle,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final code = state.classCode;

      // Admins
      final savedAdmins = await _roles.getAdminsFor(code);
      final admins = savedAdmins.isEmpty
          ? <String>{currentUserHandle}
          : savedAdmins;
      if (savedAdmins.isEmpty) {
        await _roles.saveAdminsFor(code, admins);
      }

      // Members
      final savedMembers = await _memberships.getMembersFor(code);
      final seedMembers = <String>{
        ...initialMemberHandles,
        currentUserHandle,
      };
      final members = savedMembers.isEmpty ? seedMembers : savedMembers;
      if (savedMembers.isEmpty) {
        await _memberships.saveMembersFor(code, members);
      }

      state = state.copyWith(
        members: members,
        admins: admins,
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

  Future<void> addMember(String handle) async {
    final nextMembers = <String>{...state.members, handle};
    state = state.copyWith(members: nextMembers);
    await _memberships.saveMembersFor(state.classCode, nextMembers);
  }

  Future<void> removeMember(String handle) async {
    final nextMembers = <String>{...state.members}..remove(handle);
    state = state.copyWith(members: nextMembers);
    await _memberships.saveMembersFor(state.classCode, nextMembers);
  }

  Future<void> saveMembers(Set<String> members) async {
    state = state.copyWith(members: members);
    await _memberships.saveMembersFor(state.classCode, members);
  }
}

