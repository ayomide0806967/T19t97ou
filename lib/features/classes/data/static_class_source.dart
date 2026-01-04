import '../../../models/college.dart';
import '../domain/class_source.dart';

/// In-memory/demo implementation backed by the previous ClassService data.
class StaticClassSource implements ClassSource {
  StaticClassSource();

  // Empty collection by default; real data should come from backend.
  static final List<College> _colleges = <College>[];

  @override
  List<College> userColleges(String handle) {
    if (handle.isEmpty) return _colleges;
    return _colleges
        .where((c) => c.memberHandles.contains(handle))
        .toList(growable: false);
  }

  @override
  List<College> allColleges() => List<College>.unmodifiable(_colleges);

  @override
  College? findByCode(String code) {
    if (code.isEmpty) return null;
    final lookup = code.toUpperCase();
    try {
      return _colleges.firstWhere(
        (c) => c.code.toUpperCase() == lookup,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  List<College> searchPublicColleges(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return allColleges();
    return _colleges.where((college) {
      final name = college.name.toLowerCase();
      final facilitator = college.facilitator.toLowerCase();
      final upcoming = college.upcomingExam.toLowerCase();
      return name.contains(q) ||
          facilitator.contains(q) ||
          upcoming.contains(q);
    }).toList(growable: false);
  }
}
