import '../../../models/college.dart';

/// Abstraction over how "classes"/colleges are retrieved for a user.
abstract class ClassSource {
  List<College> userColleges(String handle);

  /// Returns all known colleges (for discovery/search experiences).
  List<College> allColleges();

  /// Finds a college by its code (case-insensitive). Returns `null` if not found.
  College? findByCode(String code);

  /// Searches public colleges by a free-text query.
  List<College> searchPublicColleges(String query);
}
