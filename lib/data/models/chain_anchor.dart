import 'dart:convert';

/// Satu "jangkar": hash catatan logbook terbaru yang ditulis ke blockchain lewat satu transaksi.
/// Karena tiap hash sudah memuat hash catatan sebelumnya, satu hash terakhir mewakili seluruh rantai
/// sampai catatan ke-[entryCount].
class ChainAnchor {
  const ChainAnchor({
    required this.headHash,
    required this.entryCount,
    required this.txHash,
    required this.createdAt,
    this.confirmed = false,
  });

  /// Hash catatan terakhir saat dijangkarkan.
  final String headHash;

  /// Jumlah catatan yang tercakup, sekaligus nomor urut catatan yang hash-nya dijangkarkan.
  final int entryCount;

  /// Nomor transaksi di blockchain (diawali 0x).
  final String txHash;

  /// Waktu dijangkarkan (UTC), format ISO 8601.
  final String createdAt;

  /// True setelah transaksi terbukti masuk blok.
  final bool confirmed;

  ChainAnchor copyWith({bool? confirmed}) {
    return ChainAnchor(
      headHash: headHash,
      entryCount: entryCount,
      txHash: txHash,
      createdAt: createdAt,
      confirmed: confirmed ?? this.confirmed,
    );
  }

  String toJson() {
    return jsonEncode({
      'head_hash': headHash,
      'entry_count': entryCount,
      'tx_hash': txHash,
      'created_at': createdAt,
      'confirmed': confirmed,
    });
  }

  factory ChainAnchor.fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    return ChainAnchor(
      headHash: map['head_hash'] as String,
      entryCount: map['entry_count'] as int,
      txHash: map['tx_hash'] as String,
      createdAt: map['created_at'] as String,
      confirmed: map['confirmed'] as bool? ?? false,
    );
  }
}
