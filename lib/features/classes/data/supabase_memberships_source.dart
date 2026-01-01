import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/class_memberships_source.dart';

/// Supabase implementation of [ClassMembershipsSource].
///
/// Manages class membership data in `class_memberships` table.
class SupabaseMembershipsSource implements ClassMembershipsSource {
  SupabaseMembershipsSource(this._client);

  final SupabaseClient _client;

  @override
  Future<Set<String>> getMembersFor(String classCode) async {
    final rows = await _client
        .from('class_memberships')
        .select('user_handle')
        .eq('class_code', classCode);

    return Set<String>.from(
      (rows as List).map((row) => row['user_handle'] as String),
    );
  }

  @override
  Future<void> saveMembersFor(String classCode, Set<String> members) async {
    // Get existing members
    final existing = await getMembersFor(classCode);

    // Remove members no longer in the set
    final toRemove = existing.difference(members);
    for (final handle in toRemove) {
      await _client
          .from('class_memberships')
          .delete()
          .eq('class_code', classCode)
          .eq('user_handle', handle);
    }

    // Add new members
    final toAdd = members.difference(existing);
    if (toAdd.isNotEmpty) {
      final inserts = toAdd
          .map((handle) => {
                'class_code': classCode,
                'user_handle': handle,
              })
          .toList();
      await _client.from('class_memberships').insert(inserts);
    }
  }
}
