/// Abstraction over class admin roles for a given class code.
abstract class ClassRolesSource {
  Future<Set<String>> getAdminsFor(String classCode);
  Future<void> saveAdminsFor(String classCode, Set<String> admins);
}

