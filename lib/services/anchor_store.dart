import 'package:shared_preferences/shared_preferences.dart';

import 'package:divefriend/data/models/chain_anchor.dart';

/// Daftar jangkar blockchain milik tiap pengguna, disimpan lokal. Urutannya dari yang terlama ke terbaru.
class AnchorStore {
  String _key(int userId) => 'chain_anchors_$userId';

  Future<List<ChainAnchor>> all(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key(userId)) ?? const <String>[];
    return [for (final item in saved) ChainAnchor.fromJson(item)];
  }

  Future<void> add(int userId, ChainAnchor anchor) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key(userId)) ?? const <String>[];
    await prefs.setStringList(_key(userId), [...saved, anchor.toJson()]);
  }

  /// Menandai jangkar dengan nomor transaksi ini sebagai sudah terkonfirmasi.
  Future<void> markConfirmed(int userId, String txHash) async {
    final anchors = await all(userId);
    final updated = [
      for (final anchor in anchors) anchor.txHash == txHash ? anchor.copyWith(confirmed: true) : anchor,
    ];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(userId), [for (final anchor in updated) anchor.toJson()]);
  }

  Future<void> clear(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
  }
}
