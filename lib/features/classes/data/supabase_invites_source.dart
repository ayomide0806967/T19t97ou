import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/class_invites_source.dart';

/// Supabase implementation of [ClassInvitesSource].
///
/// Stores invite codes in `class_invites` table.
class SupabaseInvitesSource implements ClassInvitesSource {
  SupabaseInvitesSource(this._client);

  final SupabaseClient _client;

  @override
  Future<String> getOrCreateCode(String classCode) async {
    // Check if invite code exists
    final existing = await _client
        .from('class_invites')
        .select('invite_code')
        .eq('class_code', classCode)
        .maybeSingle();

    if (existing != null) {
      return existing['invite_code'] as String;
    }

    // Generate new invite code
    final inviteCode = _generateCode();
    await _client.from('class_invites').insert({
      'class_code': classCode,
      'invite_code': inviteCode,
    });

    return inviteCode;
  }

  @override
  Future<Map<String, String>> getAllCodes() async {
    final rows = await _client.from('class_invites').select();
    final result = <String, String>{};
    for (final row in rows as List) {
      result[row['class_code'] as String] = row['invite_code'] as String;
    }
    return result;
  }

  @override
  Future<String?> resolve(String inviteCode) async {
    final row = await _client
        .from('class_invites')
        .select('class_code')
        .eq('invite_code', inviteCode)
        .maybeSingle();

    return row?['class_code'] as String?;
  }

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer();
    for (var i = 0; i < 8; i++) {
      buffer.write(chars[(random + i * 17) % chars.length]);
    }
    return buffer.toString();
  }
}
