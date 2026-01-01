import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/class_roles_source.dart';

/// Supabase implementation of [ClassRolesSource].
///
/// Manages class admin roles in `class_roles` table.
class SupabaseRolesSource implements ClassRolesSource {
  SupabaseRolesSource(this._client);

  final SupabaseClient _client;

  @override
  Future<Set<String>> getAdminsFor(String classCode) async {
    final rows = await _client
        .from('class_roles')
        .select('user_handle')
        .eq('class_code', classCode)
        .eq('role', 'admin');

    return Set<String>.from(
      (rows as List).map((row) => row['user_handle'] as String),
    );
  }

  @override
  Future<void> saveAdminsFor(String classCode, Set<String> admins) async {
    // Get existing admins
    final existing = await getAdminsFor(classCode);

    // Remove admins no longer in the set
    final toRemove = existing.difference(admins);
    for (final handle in toRemove) {
      await _client
          .from('class_roles')
          .delete()
          .eq('class_code', classCode)
          .eq('user_handle', handle)
          .eq('role', 'admin');
    }

    // Add new admins
    final toAdd = admins.difference(existing);
    if (toAdd.isNotEmpty) {
      final inserts = toAdd
          .map((handle) => {
                'class_code': classCode,
                'user_handle': handle,
                'role': 'admin',
              })
          .toList();
      await _client.from('class_roles').insert(inserts);
    }
  }
}
