import 'package:shared_preferences/shared_preferences.dart';

/// Kesan dan saran mata kuliah PAM milik satu pengguna.
class FeedbackEntry {
  const FeedbackEntry({required this.impression, required this.suggestion});

  final String impression;
  final String suggestion;
}

/// Menyimpan saran dan kesan secara lokal per pengguna di shared_preferences.
class FeedbackStore {
  String _impressionKey(int userId) => 'feedback_impression_$userId';
  String _suggestionKey(int userId) => 'feedback_suggestion_$userId';

  /// Null kalau pengguna belum pernah menyimpan.
  Future<FeedbackEntry?> load(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final impression = prefs.getString(_impressionKey(userId));
    final suggestion = prefs.getString(_suggestionKey(userId));
    if (impression == null || suggestion == null) return null;
    return FeedbackEntry(impression: impression, suggestion: suggestion);
  }

  Future<void> save(int userId, FeedbackEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_impressionKey(userId), entry.impression);
    await prefs.setString(_suggestionKey(userId), entry.suggestion);
  }
}
