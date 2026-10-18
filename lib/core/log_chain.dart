import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:divefriend/data/models/log_entry.dart';

/// Nilai "catatan sebelumnya" untuk catatan pertama (64 angka nol, sepanjang satu hash SHA-256).
final String genesisHash = '0' * 64;

/// Hash SHA-256 sebuah catatan. Bahannya semua isi catatan ditambah hash catatan sebelumnya,
/// ditulis sebagai daftar JSON supaya batas antar bagian selalu jelas (tidak ambigu walau catatan
/// berisi karakter aneh). Mengubah satu huruf saja akan menghasilkan hash yang sama sekali berbeda.
String computeEntryHash(LogEntry entry) {
  final canonical = jsonEncode([
    entry.prevHash,
    entry.userId,
    entry.seq,
    entry.diveDate,
    entry.spotId,
    entry.spotName,
    entry.maxDepthM,
    entry.bottomTimeMin,
    entry.notes,
    entry.createdAt,
  ]);
  return sha256.convert(utf8.encode(canonical)).toString();
}

enum ChainProblem {
  /// Nomor urut loncat, artinya ada catatan yang hilang sebelum catatan ini.
  sequenceGap,

  /// Hash catatan sebelumnya tidak cocok, artinya catatan sebelumnya diubah atau ada yang disisipkan.
  previousHashMismatch,

  /// Isi catatan tidak cocok dengan hash miliknya sendiri, artinya isinya diubah.
  contentMismatch,
}

/// Hasil pengecekan rantai. [brokenSeq] dan [problem] terisi hanya kalau rantai rusak.
class ChainReport {
  const ChainReport({required this.checked, this.brokenSeq, this.problem});

  /// Jumlah catatan yang diperiksa.
  final int checked;
  final int? brokenSeq;
  final ChainProblem? problem;

  bool get isValid => problem == null;
}

/// Memeriksa rantai dari catatan pertama sampai terakhir dan berhenti di catatan pertama yang bermasalah.
/// [entries] harus sudah urut menurut nomor urut.
ChainReport verifyChain(List<LogEntry> entries) {
  var expectedSeq = 1;
  var expectedPrevHash = genesisHash;
  for (final entry in entries) {
    final problem = _findProblem(entry, expectedSeq, expectedPrevHash);
    if (problem != null) {
      return ChainReport(checked: entries.length, brokenSeq: entry.seq, problem: problem);
    }
    expectedSeq++;
    expectedPrevHash = entry.hash;
  }
  return ChainReport(checked: entries.length);
}

ChainProblem? _findProblem(LogEntry entry, int expectedSeq, String expectedPrevHash) {
  if (entry.seq != expectedSeq) return ChainProblem.sequenceGap;
  if (entry.prevHash != expectedPrevHash) return ChainProblem.previousHashMismatch;
  if (entry.hash != computeEntryHash(entry)) return ChainProblem.contentMismatch;
  return null;
}

/// Teks hasil pengecekan untuk pengguna.
String describeChainReport(ChainReport report) {
  if (report.checked == 0) return 'Logbook masih kosong, belum ada catatan yang dicek.';
  final seq = report.brokenSeq;
  return switch (report.problem) {
    null => 'Rantai utuh. Semua ${report.checked} catatan cocok dengan hash-nya dan terhubung berurutan.',
    ChainProblem.contentMismatch =>
      'Catatan #$seq berubah. Isinya tidak lagi cocok dengan hash yang tersimpan.',
    ChainProblem.previousHashMismatch =>
      'Catatan #$seq tidak terhubung ke catatan sebelumnya. Ada catatan yang diubah atau disisipkan.',
    ChainProblem.sequenceGap =>
      'Nomor catatan loncat di #$seq. Ada catatan yang hilang sebelum nomor ini.',
  };
}
