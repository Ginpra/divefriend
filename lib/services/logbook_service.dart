import 'package:divefriend/core/log_chain.dart';
import 'package:divefriend/data/models/log_entry.dart';
import 'package:divefriend/data/repositories/logbook_repository.dart';

/// Logbook dengan hash chain ("blockchain sederhana"): catatan hanya bisa ditambah di ujung rantai,
/// tidak bisa diubah atau dihapus lewat aplikasi, dan setiap catatan membawa hash catatan sebelumnya.
/// Cek Integritas menghitung ulang seluruh rantai untuk mendeteksi catatan yang diubah.
///
/// Batasan yang jujur: hash chain tanpa kunci rahasia atau server pembanding hanya mendeteksi perubahan
/// yang tidak rapi. Orang yang bisa menghitung ulang seluruh rantai dari catatan yang ia ubah tetap
/// lolos, dan catatan yang dihapus dari ujung rantai tidak terlihat.
class LogbookService {
  LogbookService(this._repository, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final LogbookRepository _repository;
  final DateTime Function() _clock;

  /// Tanda yang ditempelkan simulasi pemalsuan, dipakai juga untuk memulihkannya.
  static const String tamperMarker = ' [DIUBAH]';

  Future<List<LogEntry>> entries(int userId) => _repository.entriesFor(userId);

  Future<LogEntry> addEntry({
    required int userId,
    required DateTime diveDate,
    required String spotId,
    required String spotName,
    required int maxDepthM,
    required int bottomTimeMin,
    required String notes,
  }) async {
    final existing = await _repository.entriesFor(userId);
    final previous = existing.isEmpty ? null : existing.last;
    final draft = LogEntry(
      userId: userId,
      seq: (previous?.seq ?? 0) + 1,
      diveDate: formatIsoDate(diveDate),
      spotId: spotId,
      spotName: spotName,
      maxDepthM: maxDepthM,
      bottomTimeMin: bottomTimeMin,
      notes: notes.trim(),
      createdAt: _clock().toUtc().toIso8601String(),
      prevHash: previous?.hash ?? genesisHash,
      hash: '',
    );
    final entry = draft.withHash(computeEntryHash(draft));
    await _repository.insert(entry);
    return entry;
  }

  Future<ChainReport> verify(int userId) async {
    return verifyChain(await _repository.entriesFor(userId));
  }

  /// KHUSUS DEMO: memalsukan isi catatan pertama tanpa menghitung ulang hash-nya.
  /// False kalau logbook masih kosong.
  Future<bool> simulateTampering(int userId) async {
    final entries = await _repository.entriesFor(userId);
    if (entries.isEmpty) return false;
    final first = entries.first;
    if (!first.notes.endsWith(tamperMarker)) {
      await _repository.rewriteNotesWithoutRehash(userId, first.seq, first.notes + tamperMarker);
    }
    return true;
  }

  /// KHUSUS DEMO: mengembalikan catatan yang dipalsukan oleh [simulateTampering].
  Future<void> restoreSimulation(int userId) async {
    for (final entry in await _repository.entriesFor(userId)) {
      if (entry.notes.endsWith(tamperMarker)) {
        final original = entry.notes.substring(0, entry.notes.length - tamperMarker.length);
        await _repository.rewriteNotesWithoutRehash(userId, entry.seq, original);
      }
    }
  }
}

/// Tanggal dalam format "2026-10-18".
String formatIsoDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

/// Mengubah "2026-10-18" menjadi "18-10-2026" untuk tampilan. Teks lain dikembalikan apa adanya.
String formatDisplayDate(String isoDate) {
  final parts = isoDate.split('-');
  if (parts.length != 3) return isoDate;
  return '${parts[2]}-${parts[1]}-${parts[0]}';
}
