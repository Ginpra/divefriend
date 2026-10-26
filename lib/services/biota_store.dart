import 'package:shared_preferences/shared_preferences.dart';

import 'package:divefriend/core/encounter_grade.dart';
import 'package:divefriend/core/quiz_builder.dart';

/// Hasil undian biota terakhir, koleksi biota yang pernah ditemukan, dan grade terbaik tiap biota,
/// disimpan lokal per pengguna. Dengan ini hasil undian tidak hilang saat layar game ditutup.
class BiotaStore {
  String _lastKey(int userId) => 'biota_last_$userId';
  String _foundKey(int userId) => 'biota_found_$userId';
  String _gradesKey(int userId) => 'biota_grades_$userId';

  Future<BiotaPick?> last(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_lastKey(userId));
    if (saved == null || saved.length < 2) return null;
    // Data lama hanya berisi nama dan spot, jadi grade-nya dianggap Biasa.
    final grade = saved.length > 2 ? gradeFromIndex(int.tryParse(saved[2]) ?? 0) : EncounterGrade.biasa;
    return BiotaPick(name: saved[0], spotName: saved[1], grade: grade);
  }

  /// Kunci biota yang pernah ditemukan (lihat [biotaKey]).
  Future<Set<String>> found(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_foundKey(userId)) ?? const <String>[]).toSet();
  }

  /// Grade tertinggi yang pernah didapat tiap biota. Biota tanpa catatan dianggap Biasa.
  /// Tiap baris tersimpan sebagai "angkaGrade#kunciBiota".
  Future<Map<String, EncounterGrade>> bestGrades(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_gradesKey(userId)) ?? const <String>[];
    final result = <String, EncounterGrade>{};
    for (final line in saved) {
      final split = line.indexOf('#');
      if (split <= 0) continue;
      final index = int.tryParse(line.substring(0, split));
      if (index == null) continue;
      result[line.substring(split + 1)] = gradeFromIndex(index);
    }
    return result;
  }

  /// Mencatat undian terbaru dan menambahkannya ke koleksi. True kalau biota ini baru pertama kali ditemukan.
  Future<bool> record(int userId, BiotaPick pick) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_lastKey(userId), [pick.name, pick.spotName, '${pick.grade.index}']);
    final key = biotaKey(pick.name, pick.spotName);

    final grades = await bestGrades(userId);
    final previous = grades[key];
    if (previous == null || pick.grade.index > previous.index) {
      grades[key] = pick.grade;
      await prefs.setStringList(
        _gradesKey(userId),
        [for (final entry in grades.entries) '${entry.value.index}#${entry.key}'],
      );
    }

    final found = (prefs.getStringList(_foundKey(userId)) ?? const <String>[]).toSet();
    final isNew = found.add(key);
    if (isNew) await prefs.setStringList(_foundKey(userId), found.toList());
    return isNew;
  }

  Future<void> clear(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastKey(userId));
    await prefs.remove(_foundKey(userId));
    await prefs.remove(_gradesKey(userId));
  }
}
