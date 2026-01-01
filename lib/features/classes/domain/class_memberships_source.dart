/// Abstraction over class membership persistence for a given class code.
abstract class ClassMembershipsSource {
  Future<Set<String>> getMembersFor(String classCode);
  Future<void> saveMembersFor(String classCode, Set<String> members);
}

