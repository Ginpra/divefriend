import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/core/anchor_check.dart';
import 'package:divefriend/core/log_chain.dart';
import 'package:divefriend/data/models/chain_anchor.dart';
import 'package:divefriend/data/models/log_entry.dart';

/// Membuat rantai logbook yang valid dengan [count] catatan.
List<LogEntry> buildChain(int count, {String notePrefix = 'catatan'}) {
  var previousHash = genesisHash;
  final entries = <LogEntry>[];
  for (var seq = 1; seq <= count; seq++) {
    final draft = LogEntry(
      userId: 1,
      seq: seq,
      diveDate: '2026-10-0$seq',
      spotId: 'komodo',
      spotName: 'Komodo',
      maxDepthM: 20,
      bottomTimeMin: 40,
      notes: '$notePrefix $seq',
      createdAt: '2026-10-2${seq}T00:00:00.000Z',
      prevHash: previousHash,
      hash: '',
    );
    final sealed = draft.withHash(computeEntryHash(draft));
    previousHash = sealed.hash;
    entries.add(sealed);
  }
  return entries;
}

ChainAnchor anchorFor(List<LogEntry> entries) {
  return ChainAnchor(
    headHash: entries.last.hash,
    entryCount: entries.length,
    txHash: '0xabc',
    createdAt: '2026-10-27T00:00:00.000Z',
  );
}

void main() {
  group('isi transaksi', () {
    test('dibangun dan dibaca kembali dengan hash yang sama', () {
      final hash = 'a' * 64;
      expect(parseAnchorPayload(buildAnchorPayload(hash)), hash);
    });

    test('isi yang bukan buatan DiveFriend atau hash-nya cacat ditolak', () {
      expect(parseAnchorPayload('hello'), isNull);
      expect(parseAnchorPayload('${anchorPayloadPrefix}pendek'), isNull);
      expect(parseAnchorPayload('$anchorPayloadPrefix${'A' * 64}'), isNull);
    });
  });

  group('verifyAnchor', () {
    test('cocok kalau blockchain dan logbook di HP sama', () {
      final entries = buildChain(3);
      final anchor = anchorFor(entries);

      final verdict = verifyAnchor(
        anchor: anchor,
        entries: entries,
        onChainPayload: buildAnchorPayload(anchor.headHash),
      );

      expect(verdict, AnchorVerdict.verified);
    });

    test('catatan baru sesudah dijangkarkan tidak merusak jangkar lama', () {
      final anchored = buildChain(2);
      final anchor = anchorFor(anchored);
      final later = buildChain(3);

      final verdict = verifyAnchor(
        anchor: anchor,
        entries: later,
        onChainPayload: buildAnchorPayload(anchor.headHash),
      );

      expect(verdict, AnchorVerdict.verified);
    });

    test('transaksi tidak ditemukan', () {
      final entries = buildChain(2);

      expect(
        verifyAnchor(anchor: anchorFor(entries), entries: entries, onChainPayload: null),
        AnchorVerdict.notOnChain,
      );
    });

    test('isi transaksi berbeda dari jangkar', () {
      final entries = buildChain(2);

      expect(
        verifyAnchor(
          anchor: anchorFor(entries),
          entries: entries,
          onChainPayload: buildAnchorPayload('b' * 64),
        ),
        AnchorVerdict.payloadMismatch,
      );
    });

    test('isi catatan diubah tanpa hitung ulang hash: rantai rusak', () {
      final entries = buildChain(3);
      final anchor = anchorFor(entries);
      final tampered = [entries[0], entries[1].withNotes('dipalsukan'), entries[2]];

      expect(
        verifyAnchor(anchor: anchor, entries: tampered, onChainPayload: buildAnchorPayload(anchor.headHash)),
        AnchorVerdict.localChainBroken,
      );
    });

    test('diubah lalu disegel ulang: rantai valid tapi riwayat berbeda, ketahuan oleh blockchain', () {
      final entries = buildChain(3);
      final anchor = anchorFor(entries);
      final resealed = buildChain(3, notePrefix: 'dipalsukan');

      expect(verifyChain(resealed).isValid, isTrue);
      expect(
        verifyAnchor(anchor: anchor, entries: resealed, onChainPayload: buildAnchorPayload(anchor.headHash)),
        AnchorVerdict.localHistoryChanged,
      );
    });

    test('catatan dihapus sehingga jumlahnya kurang dari yang dijangkarkan', () {
      final entries = buildChain(3);
      final anchor = anchorFor(entries);

      expect(
        verifyAnchor(
          anchor: anchor,
          entries: buildChain(2),
          onChainPayload: buildAnchorPayload(anchor.headHash),
        ),
        AnchorVerdict.localHistoryChanged,
      );
    });
  });
}
