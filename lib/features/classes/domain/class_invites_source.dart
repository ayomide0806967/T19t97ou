/// Abstraction over class invite codes.
abstract class ClassInvitesSource {
  Future<String> getOrCreateCode(String classCode);
  Future<Map<String, String>> getAllCodes();
  Future<String?> resolve(String inviteCode);
}

