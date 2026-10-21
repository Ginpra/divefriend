import 'package:shared_preferences/shared_preferences.dart';

/// Skor tertinggi kuis biota, disimpan lokal per pengguna di shared_preferences.
class QuizScoreStore {
  String _key(int userId) => 'quiz_best_score_$userId';

  Future<int> bestScore(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(userId)) ?? 0;
  }

  /// Menyimpan [score] kalau lebih tinggi dari rekor lama. True kalau ini rekor baru.
  Future<bool> saveIfBest(int userId, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final best = prefs.getInt(_key(userId)) ?? 0;
    if (score <= best) return false;
    await prefs.setInt(_key(userId), score);
    return true;
  }
}
