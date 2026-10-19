import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/core/log_chain.dart';
import 'package:divefriend/data/models/log_entry.dart';

LogEntry _entry({
  required int seq,
  required String prevHash,
  int userId = 1,
  String notes = 'Arus tenang',
  String spotName = 'Kepulauan Banda',
}) {
  final draft = LogEntry(
    userId: userId,
    seq: seq,
    diveDate: '2026-10-18',
    spotId: 'banda',
    spotName: spotName,
    maxDepthM: 18,
    bottomTimeMin: 45,
    notes: notes,
    createdAt: '2026-10-18T03:00:00.000Z',
    prevHash: prevHash,
    hash: '',
  );
  return draft.withHash(computeEntryHash(draft));
}

List<LogEntry> _chainOf(int length) {
  final entries = <LogEntry>[];
  var prev = genesisHash;
  for (var seq = 1; seq <= length; seq++) {
    final entry = _entry(seq: seq, prevHash: prev, notes: 'Catatan $seq');
    entries.add(entry);
    prev = entry.hash;
  }
  return entries;
}

void main() {
  group('computeEntryHash', () {
    test('hash catatan pertama cocok dengan hitungan SHA-256 terpisah', () {
      final entry = _entry(seq: 1, prevHash: genesisHash);
      expect(entry.hash, 'eeac80dda6e9185272ac5e61deeb0c43d556fcab718571d4d1dd85775273592d');
    });

    test('hash catatan kedua memuat hash catatan pertama', () {
      final first = _entry(seq: 1, prevHash: genesisHash);
      final second = LogEntry(
        userId: 1,
        seq: 2,
        diveDate: '2026-10-19',
        spotId: 'raja-ampat',
        spotName: 'Raja Ampat',
        maxDepthM: 25,
        bottomTimeMin: 50,
        notes: 'Manta di cleaning station',
        createdAt: '2026-10-18T03:00:00.000Z',
        prevHash: first.hash,
        hash: '',
      );
      expect(
        computeEntryHash(second),
        '7559e2d708a7cb9a43c9b16d4e7deced1bdc631613a42cf4228da68ab3b1b415',
      );
    });

    test('karakter khusus (garis tegak, kutip, garis miring balik) tidak merusak hash', () {
      final entry = LogEntry(
        userId: 2,
        seq: 1,
        diveDate: '2026-10-18',
        spotId: 'komodo',
        spotName: 'Taman Nasional Komodo',
        maxDepthM: 30,
        bottomTimeMin: 40,
        notes: 'Arus kuat | "catatan" \\ miring',
        createdAt: '2026-10-18T03:00:00.000Z',
        prevHash: genesisHash,
        hash: '',
      );
      expect(
        computeEntryHash(entry),
        '84dc8673dd3f2e8561c12f9a38f279f157119e0bf130dbfced2e40d92a646076',
      );
    });

    test('catatan tanpa updatedAt memakai daftar lama, dengan updatedAt hash-nya berubah', () {
      final plain = _entry(seq: 1, prevHash: genesisHash);
      final edited = plain.copyWith(updatedAt: '2026-10-19T05:00:00.000Z');
      expect(computeEntryHash(plain), plain.hash);
      expect(computeEntryHash(edited), isNot(plain.hash));
    });

    test('mengubah satu huruf menghasilkan hash yang berbeda', () {
      final original = _entry(seq: 1, prevHash: genesisHash, notes: 'Arus tenang');
      final changed = _entry(seq: 1, prevHash: genesisHash, notes: 'Arus tenanG');
      expect(changed.hash, isNot(original.hash));
      expect(original.hash.length, 64);
    });
  });

  group('verifyChain', () {
    test('rantai kosong dianggap utuh dengan nol catatan', () {
      final report = verifyChain(const []);
      expect(report.isValid, isTrue);
      expect(report.checked, 0);
    });

    test('rantai yang dibangun benar dinyatakan utuh', () {
      final report = verifyChain(_chainOf(5));
      expect(report.isValid, isTrue);
      expect(report.checked, 5);
      expect(report.brokenSeq, isNull);
    });

    test('isi catatan diubah: terdeteksi di catatan itu sebagai contentMismatch', () {
      final chain = _chainOf(4);
      chain[1] = chain[1].withNotes('DIPALSUKAN');
      final report = verifyChain(chain);
      expect(report.isValid, isFalse);
      expect(report.brokenSeq, 2);
      expect(report.problem, ChainProblem.contentMismatch);
    });

    test('catatan diubah lalu hash-nya dihitung ulang: ketahuan di catatan berikutnya', () {
      final chain = _chainOf(4);
      final tampered = chain[1].withNotes('DIPALSUKAN');
      chain[1] = tampered.withHash(computeEntryHash(tampered));
      final report = verifyChain(chain);
      expect(report.brokenSeq, 3);
      expect(report.problem, ChainProblem.previousHashMismatch);
    });

    test('catatan di tengah hilang: terdeteksi sebagai nomor loncat', () {
      final chain = _chainOf(4)..removeAt(1);
      final report = verifyChain(chain);
      expect(report.brokenSeq, 3);
      expect(report.problem, ChainProblem.sequenceGap);
    });

    test('catatan pertama dihapus: terdeteksi karena nomor tidak mulai dari 1', () {
      final chain = _chainOf(3)..removeAt(0);
      final report = verifyChain(chain);
      expect(report.brokenSeq, 2);
      expect(report.problem, ChainProblem.sequenceGap);
    });

    test('catatan terakhir dihapus tidak terdeteksi (batas hash chain tanpa pembanding)', () {
      final chain = _chainOf(4)..removeLast();
      expect(verifyChain(chain).isValid, isTrue);
    });
  });

  group('describeChainReport', () {
    test('kalimat untuk tiap kondisi', () {
      expect(
        describeChainReport(verifyChain(const [])),
        'Logbook masih kosong, belum ada catatan yang dicek.',
      );
      expect(
        describeChainReport(verifyChain(_chainOf(3))),
        'Rantai utuh. Semua 3 catatan cocok dengan hash-nya dan terhubung berurutan.',
      );

      final changed = _chainOf(3);
      changed[0] = changed[0].withNotes('x');
      expect(
        describeChainReport(verifyChain(changed)),
        'Catatan #1 berubah. Isinya tidak lagi cocok dengan hash yang tersimpan.',
      );

      final gap = _chainOf(3)..removeAt(1);
      expect(
        describeChainReport(verifyChain(gap)),
        'Nomor catatan loncat di #3. Ada catatan yang hilang sebelum nomor ini.',
      );
    });

    test('teks tidak memakai titik koma', () {
      final texts = [
        describeChainReport(verifyChain(const [])),
        describeChainReport(verifyChain(_chainOf(2))),
      ];
      for (final text in texts) {
        expect(text.contains(';'), isFalse);
      }
    });
  });
}
