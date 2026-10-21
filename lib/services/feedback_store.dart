import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Satu catatan kesan dan saran mata kuliah PAM.
class FeedbackEntry {
  const FeedbackEntry({
    required this.id,
    required this.impression,
    required this.suggestion,
    required this.createdAt,
  });

  /// Dibuat dari waktu penyimpanan (milidetik), dipakai untuk menghapus satu catatan.
  final int id;
  final String impression;
  final String suggestion;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'impression': impression,
        'suggestion': suggestion,
        'createdAt': createdAt.toIso8601String(),
      };

  static FeedbackEntry? fromJson(Object? decoded) {
    if (decoded is! Map<String, dynamic>) return null;
    final id = decoded['id'];
    final impression = decoded['impression'];
    final suggestion = decoded['suggestion'];
    final createdAt = DateTime.tryParse('${decoded['createdAt']}');
    if (id is! int || impression is! String || suggestion is! String || createdAt == null) return null;
    return FeedbackEntry(id: id, impression: impression, suggestion: suggestion, createdAt: createdAt);
  }
}

/// Riwayat saran dan kesan per pengguna, disimpan lokal di shared_preferences.
/// Ini catatan biasa (bisa ditambah dan dihapus), bukan hash chain seperti logbook.
class FeedbackStore {
  String _key(int userId) => 'feedback_history_$userId';

  /// Semua catatan milik [userId], yang terbaru di atas.
  Future<List<FeedbackEntry>> history(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(userId)) ?? const <String>[];
    final entries = <FeedbackEntry>[];
    for (final line in raw) {
      try {
        final entry = FeedbackEntry.fromJson(jsonDecode(line));
        if (entry != null) entries.add(entry);
      } on FormatException {
        // Baris rusak dilewati supaya riwayat lain tetap tampil.
      }
    }
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<void> add(
    int userId, {
    required String impression,
    required String suggestion,
    DateTime? now,
  }) async {
    final time = now ?? DateTime.now();
    final entry = FeedbackEntry(
      id: time.millisecondsSinceEpoch,
      impression: impression,
      suggestion: suggestion,
      createdAt: time,
    );
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(userId)) ?? const <String>[];
    await prefs.setStringList(_key(userId), [...raw, jsonEncode(entry.toJson())]);
  }

  Future<void> remove(int userId, int id) async {
    final remaining = (await history(userId)).where((entry) => entry.id != id).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(userId), [for (final entry in remaining) jsonEncode(entry.toJson())]);
  }

  /// Menghapus seluruh riwayat milik [userId] (dipakai saat akun dihapus).
  Future<void> clear(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
  }
}
