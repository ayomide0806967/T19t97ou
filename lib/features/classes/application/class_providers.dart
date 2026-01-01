import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/local_invites_source.dart';
import '../data/local_memberships_source.dart';
import '../data/local_roles_source.dart';
import '../data/static_class_source.dart';
import '../domain/class_invites_source.dart';
import '../domain/class_memberships_source.dart';
import '../domain/class_roles_source.dart';
import '../domain/class_source.dart';

part 'class_providers.g.dart';

/// Provides the current [ClassSource] implementation.
@riverpod
ClassSource classSource(Ref ref) => StaticClassSource();

/// Provides the current [ClassMembershipsSource] implementation.
@riverpod
ClassMembershipsSource classMembershipsSource(Ref ref) =>
    LocalClassMembershipsSource();

/// Provides the current [ClassRolesSource] implementation.
@riverpod
ClassRolesSource classRolesSource(Ref ref) => LocalClassRolesSource();

/// Provides the current [ClassInvitesSource] implementation.
@riverpod
ClassInvitesSource classInvitesSource(Ref ref) => LocalClassInvitesSource();
