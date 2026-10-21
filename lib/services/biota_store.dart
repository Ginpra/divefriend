import 'package:shared_preferences/shared_preferences.dart';

import 'package:divefriend/core/quiz_builder.dart';

/// Hasil undian biota terakhir dan koleksi biota yang pernah ditemukan, disimpan lokal per pengguna.
/// Dengan ini hasil undian tidak hilang saat layar game ditutup.
class BiotaStore {
  String _lastKey(int userId) => 'biota_last_$userId';
  String _foundKey(int userId) => 'biota_found_$userId';

  Future<BiotaPick?> last(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_lastKey(userId));
    if (saved == null || saved.length != 2) return null;
    return BiotaPick(name: saved[0], spotName: saved[1]);
  }

  /// Kunci biota yang pernah ditemukan (lihat [biotaKey]).
  Future<Set<String>> found(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_foundKey(userId)) ?? const <String>[]).toSet();
  }

  /// Mencatat undian terbaru dan menambahkannya ke koleksi. True kalau biota ini baru pertama kali ditemukan.
  Future<bool> record(int userId, BiotaPick pick) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_lastKey(userId), [pick.name, pick.spotName]);
    final found = (prefs.getStringList(_foundKey(userId)) ?? const <String>[]).toSet();
    final isNew = found.add(biotaKey(pick.name, pick.spotName));
    if (isNew) await prefs.setStringList(_foundKey(userId), found.toList());
    return isNew;
  }

  Future<void> clear(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastKey(userId));
    await prefs.remove(_foundKey(userId));
  }
}
