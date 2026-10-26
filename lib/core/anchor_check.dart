import 'package:divefriend/core/log_chain.dart';
import 'package:divefriend/data/models/chain_anchor.dart';
import 'package:divefriend/data/models/log_entry.dart';

/// Awalan isi transaksi. Terbaca langsung di Etherscan sebagai teks, jadi mudah ditunjukkan saat demo.
const String anchorPayloadPrefix = 'DiveFriend:v1:';

/// Isi transaksi untuk satu hash logbook. Hanya hash yang ditulis, tidak ada isi catatan atau data pribadi.
String buildAnchorPayload(String headHash) => '$anchorPayloadPrefix$headHash';

/// Mengambil hash dari isi transaksi. Null kalau bukan isi buatan DiveFriend atau hash-nya tidak valid.
String? parseAnchorPayload(String payload) {
  if (!payload.startsWith(anchorPayloadPrefix)) return null;
  final hash = payload.substring(anchorPayloadPrefix.length);
  return RegExp(r'^[0-9a-f]{64}$').hasMatch(hash) ? hash : null;
}

enum AnchorVerdict {
  /// Hash di blockchain sama dengan yang tercatat, dan logbook di HP masih sama seperti saat dijangkarkan.
  verified,

  /// Transaksinya tidak ditemukan di blockchain.
  notOnChain,

  /// Transaksi ada, tapi isinya bukan hash yang tercatat di jangkar ini.
  payloadMismatch,

  /// Rantai logbook di HP rusak (isi diubah tanpa menghitung ulang hash).
  localChainBroken,

  /// Rantai di HP utuh, tapi riwayatnya berbeda dari saat dijangkarkan (ada yang diubah, disisipkan, atau dihapus).
  localHistoryChanged,
}

/// Membandingkan tiga hal: hash di blockchain, hash yang tercatat di jangkar, dan logbook di HP.
/// Ini yang membuat "Segel ulang rantai" tidak bisa menyembunyikan perubahan: hash di blockchain tidak bisa diubah.
/// [entries] harus urut menurut nomor urut. [onChainPayload] null kalau transaksinya tidak ditemukan.
AnchorVerdict verifyAnchor({
  required ChainAnchor anchor,
  required List<LogEntry> entries,
  required String? onChainPayload,
}) {
  if (onChainPayload == null) return AnchorVerdict.notOnChain;
  if (parseAnchorPayload(onChainPayload) != anchor.headHash) return AnchorVerdict.payloadMismatch;
  if (!verifyChain(entries).isValid) return AnchorVerdict.localChainBroken;
  for (final entry in entries) {
    if (entry.seq == anchor.entryCount) {
      return entry.hash == anchor.headHash ? AnchorVerdict.verified : AnchorVerdict.localHistoryChanged;
    }
  }
  return AnchorVerdict.localHistoryChanged;
}
