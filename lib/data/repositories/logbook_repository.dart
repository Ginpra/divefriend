import 'package:divefriend/data/models/log_entry.dart';

/// Kontrak penyimpanan logbook. Aslinya SQLite, saat tes diganti versi memori.
abstract class LogbookRepository {
  /// Semua catatan milik [userId], urut dari nomor 1 ke atas.
  Future<List<LogEntry>> entriesFor(int userId);

  /// Mengganti SELURUH catatan milik [userId] dengan [entries] sekaligus (atomik: semuanya tersimpan
  /// atau tidak sama sekali). Dipakai untuk tambah, ubah, dan hapus, karena setiap perubahan
  /// menyegel ulang rantai hash dan bisa menggeser nomor catatan lain.
  Future<void> replaceAll(int userId, List<LogEntry> entries);

  /// KHUSUS DEMO: mengubah isi catatan langsung di penyimpanan tanpa menghitung ulang hash,
  /// untuk memperlihatkan bahwa Cek Integritas bisa mendeteksi pemalsuan.
  Future<void> rewriteNotesWithoutRehash(int userId, int seq, String notes);
}
