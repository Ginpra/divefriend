import 'package:divefriend/data/models/log_entry.dart';

/// Kontrak penyimpanan logbook. Aslinya SQLite, saat tes diganti versi memori.
abstract class LogbookRepository {
  /// Semua catatan milik [userId], urut dari nomor 1 ke atas.
  Future<List<LogEntry>> entriesFor(int userId);

  Future<void> insert(LogEntry entry);

  /// KHUSUS DEMO: mengubah isi catatan langsung di penyimpanan tanpa menghitung ulang hash,
  /// untuk memperlihatkan bahwa Cek Integritas bisa mendeteksi pemalsuan.
  Future<void> rewriteNotesWithoutRehash(int userId, int seq, String notes);
}
