/// Satu catatan penyelaman di logbook. Setiap catatan menyimpan hash catatan sebelumnya ([prevHash])
/// dan hash dirinya sendiri ([hash]), sehingga seluruh logbook membentuk rantai (hash chain).
class LogEntry {
  const LogEntry({
    required this.userId,
    required this.seq,
    required this.diveDate,
    required this.spotId,
    required this.spotName,
    required this.maxDepthM,
    required this.bottomTimeMin,
    required this.notes,
    required this.createdAt,
    required this.prevHash,
    required this.hash,
  });

  final int userId;

  /// Nomor urut catatan milik pengguna ini, mulai dari 1 tanpa loncat.
  final int seq;

  /// Tanggal penyelaman, format "2026-10-18".
  final String diveDate;
  final String spotId;

  /// Nama spot disalin saat dicatat, supaya logbook tetap terbaca walau data spot berubah.
  final String spotName;
  final int maxDepthM;
  final int bottomTimeMin;
  final String notes;

  /// Waktu catatan dibuat (UTC), format ISO 8601.
  final String createdAt;
  final String prevHash;
  final String hash;

  LogEntry withHash(String newHash) {
    return LogEntry(
      userId: userId,
      seq: seq,
      diveDate: diveDate,
      spotId: spotId,
      spotName: spotName,
      maxDepthM: maxDepthM,
      bottomTimeMin: bottomTimeMin,
      notes: notes,
      createdAt: createdAt,
      prevHash: prevHash,
      hash: newHash,
    );
  }

  LogEntry withNotes(String newNotes) {
    return LogEntry(
      userId: userId,
      seq: seq,
      diveDate: diveDate,
      spotId: spotId,
      spotName: spotName,
      maxDepthM: maxDepthM,
      bottomTimeMin: bottomTimeMin,
      notes: newNotes,
      createdAt: createdAt,
      prevHash: prevHash,
      hash: hash,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'user_id': userId,
      'seq': seq,
      'dive_date': diveDate,
      'spot_id': spotId,
      'spot_name': spotName,
      'max_depth_m': maxDepthM,
      'bottom_time_min': bottomTimeMin,
      'notes': notes,
      'created_at': createdAt,
      'prev_hash': prevHash,
      'hash': hash,
    };
  }

  factory LogEntry.fromMap(Map<String, Object?> row) {
    return LogEntry(
      userId: row['user_id'] as int,
      seq: row['seq'] as int,
      diveDate: row['dive_date'] as String,
      spotId: row['spot_id'] as String,
      spotName: row['spot_name'] as String,
      maxDepthM: row['max_depth_m'] as int,
      bottomTimeMin: row['bottom_time_min'] as int,
      notes: row['notes'] as String,
      createdAt: row['created_at'] as String,
      prevHash: row['prev_hash'] as String,
      hash: row['hash'] as String,
    );
  }
}
