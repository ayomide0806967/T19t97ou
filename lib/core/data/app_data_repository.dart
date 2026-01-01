import 'package:shared_preferences/shared_preferences.dart';

/// Repository for app-wide data operations.
///
/// This abstracts persistence operations away from UI screens.
abstract class AppDataRepository {
  /// Clear all local data (preferences, caches).
  Future<void> clearAllLocalData();
}

/// Local implementation using SharedPreferences.
class LocalAppDataRepository implements AppDataRepository {
  @override
  Future<void> clearAllLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
