import 'package:divefriend/core/log_chain.dart';
import 'package:divefriend/data/models/log_entry.dart';
import 'package:divefriend/data/repositories/logbook_repository.dart';

/// Pesan error yang aman ditampilkan ke pengguna (misalnya rantai rusak atau catatan tidak ditemukan).
class LogbookException implements Exception {
  const LogbookException(this.message);

  final String message;
}

/// Logbook penyelaman dengan CRUD lengkap: tambah, baca, ubah, hapus.
///
/// Rantai hash tetap dijaga: setiap tambah, ubah, atau hapus dari aplikasi mengurutkan catatan menurut
/// tanggal, memberi nomor ulang 1..n, lalu menyegel ulang seluruh rantai. Karena itu Cek Integritas
/// hanya menyatakan rantai rusak kalau data diubah DI LUAR aplikasi (misalnya langsung di database).
///
/// Supaya kerusakan tidak tertutupi, ubah dan hapus ditolak selama rantai masih rusak. Pengguna bisa
/// memulihkannya atau memilih [resealChain] untuk menerima kondisi data saat ini.
///
/// Batasan yang jujur: tanpa kunci rahasia atau server pembanding, orang yang bisa menghitung ulang
/// seluruh rantai tetap lolos, dan catatan yang dihapus langsung dari database tidak selalu terlihat.
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
    final existing = await _intactEntries(userId);
    final newEntry = LogEntry(
      userId: userId,
      seq: existing.length + 1,
      diveDate: formatIsoDate(diveDate),
      spotId: spotId,
      spotName: spotName,
      maxDepthM: maxDepthM,
      bottomTimeMin: bottomTimeMin,
      notes: notes.trim(),
      createdAt: _clock().toUtc().toIso8601String(),
      prevHash: '',
      hash: '',
    );
    final result = await _commit(userId, [...existing, newEntry], target: newEntry);
    return result.sealed[result.targetIndex!];
  }

  Future<LogEntry> updateEntry({
    required int userId,
    required int seq,
    required DateTime diveDate,
    required String spotId,
    required String spotName,
    required int maxDepthM,
    required int bottomTimeMin,
    required String notes,
  }) async {
    final existing = await _intactEntries(userId);
    final index = existing.indexWhere((entry) => entry.seq == seq);
    if (index == -1) throw const LogbookException('Catatan tidak ditemukan.');

    final edited = existing[index].copyWith(
      diveDate: formatIsoDate(diveDate),
      spotId: spotId,
      spotName: spotName,
      maxDepthM: maxDepthM,
      bottomTimeMin: bottomTimeMin,
      notes: notes.trim(),
      updatedAt: _clock().toUtc().toIso8601String(),
    );
    final updated = [...existing]..[index] = edited;
    final result = await _commit(userId, updated, target: edited);
    return result.sealed[result.targetIndex!];
  }

  Future<void> deleteEntry({required int userId, required int seq}) async {
    final existing = await _intactEntries(userId);
    if (!existing.any((entry) => entry.seq == seq)) {
      throw const LogbookException('Catatan tidak ditemukan.');
    }
    await _commit(userId, existing.where((entry) => entry.seq != seq).toList());
  }

  Future<ChainReport> verify(int userId) async {
    return verifyChain(await _repository.entriesFor(userId));
  }

  /// Menerima isi catatan seperti kondisinya sekarang dan menyegel ulang rantainya. Dipakai setelah
  /// Cek Integritas menemukan masalah dan pengguna memutuskan data yang ada sekarang yang benar.
  Future<void> resealChain(int userId) async {
    await _commit(userId, await _repository.entriesFor(userId));
  }

  /// Mengambil catatan, dan menolak kalau rantainya rusak supaya perubahan tidak menutupi kerusakan.
  Future<List<LogEntry>> _intactEntries(int userId) async {
    final entries = await _repository.entriesFor(userId);
    final report = verifyChain(entries);
    if (!report.isValid) {
      throw LogbookException(
        '${describeChainReport(report)} Perubahan ditolak supaya kerusakan tidak tertutupi. '
        'Pulihkan data yang berubah, atau pilih Segel ulang rantai di menu kalau data sekarang sudah benar.',
      );
    }
    return entries;
  }

  /// Mengurutkan menurut tanggal (lalu waktu dibuat), memberi nomor ulang 1..n, menghitung rantai
  /// hash dari awal, dan menyimpan semuanya sekaligus. [target] adalah catatan yang sedang ditambah
  /// atau diubah, supaya posisinya setelah diurutkan bisa dikembalikan di [targetIndex].
  Future<({List<LogEntry> sealed, int? targetIndex})> _commit(
    int userId,
    List<LogEntry> unsealed, {
    LogEntry? target,
  }) async {
    final ordered = [...unsealed]..sort(_compareChronologically);
    final targetIndex = target == null ? null : ordered.indexWhere((entry) => identical(entry, target));
    final sealed = <LogEntry>[];
    var previousHash = genesisHash;
    for (var i = 0; i < ordered.length; i++) {
      final draft = ordered[i].copyWith(seq: i + 1, prevHash: previousHash, hash: '');
      final entry = draft.withHash(computeEntryHash(draft));
      sealed.add(entry);
      previousHash = entry.hash;
    }
    await _repository.replaceAll(userId, sealed);
    return (sealed: sealed, targetIndex: targetIndex);
  }

  static int _compareChronologically(LogEntry a, LogEntry b) {
    final byDate = a.diveDate.compareTo(b.diveDate);
    if (byDate != 0) return byDate;
    final byCreated = a.createdAt.compareTo(b.createdAt);
    if (byCreated != 0) return byCreated;
    return a.seq.compareTo(b.seq);
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
