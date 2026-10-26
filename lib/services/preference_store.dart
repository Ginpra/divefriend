import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:divefriend/data/models/spot.dart';

/// Hasil kuesioner preferensi satu pengguna: jawaban, minat, dan level hasil klasifikasi.
class UserPreference {
  const UserPreference({
    required this.answers,
    required this.interests,
    required this.level,
    required this.confidence,
  });

  final List<int> answers;
  final Set<String> interests;
  final SpotLevel level;
  final double confidence;

  Map<String, dynamic> toJson() => {
        'answers': answers,
        'interests': interests.toList(),
        'level': level.name,
        'confidence': confidence,
      };

  static UserPreference? fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'];
    final rawInterests = json['interests'];
    final rawLevel = json['level'];
    if (rawAnswers is! List || rawInterests is! List || rawLevel is! String) return null;
    SpotLevel? level;
    for (final value in SpotLevel.values) {
      if (value.name == rawLevel) level = value;
    }
    if (level == null) return null;
    return UserPreference(
      answers: [for (final item in rawAnswers) (item as num).toInt()],
      interests: {for (final item in rawInterests) item.toString()},
      level: level,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Menyimpan preferensi selam lokal per pengguna di shared_preferences.
/// Data rusak atau belum ada dibaca sebagai null (tidak pernah melempar error ke layar).
class PreferenceStore {
  String _key(int userId) => 'user_preference_$userId';

  Future<UserPreference?> load(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return UserPreference.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(int userId, UserPreference preference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId), jsonEncode(preference.toJson()));
  }

  /// Menghapus preferensi milik [userId] (dipakai saat akun dihapus).
  Future<void> clear(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
  }
}
