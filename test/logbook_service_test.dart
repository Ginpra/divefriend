import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/core/log_chain.dart';
import 'package:divefriend/core/validators.dart';
import 'package:divefriend/services/logbook_service.dart';
import 'fakes.dart';

Future<void> _addTwo(LogbookService service, {int userId = 1}) async {
  await service.addEntry(
    userId: userId,
    diveDate: DateTime(2026, 10, 18),
    spotId: 'banda',
    spotName: 'Kepulauan Banda',
    maxDepthM: 18,
    bottomTimeMin: 45,
    notes: 'Arus tenang',
  );
  await service.addEntry(
    userId: userId,
    diveDate: DateTime(2026, 10, 19),
    spotId: 'raja-ampat',
    spotName: 'Raja Ampat',
    maxDepthM: 25,
    bottomTimeMin: 50,
    notes: 'Manta di cleaning station',
  );
}

void main() {
  late InMemoryLogbookRepository repository;
  late LogbookService service;

  setUp(() {
    repository = InMemoryLogbookRepository();
    service = LogbookService(repository, clock: () => DateTime.utc(2026, 10, 18, 3));
  });

  test('catatan pertama bernomor 1, terhubung ke hash awal, dan hash-nya cocok hitungan terpisah', () async {
    final entry = await service.addEntry(
      userId: 1,
      diveDate: DateTime(2026, 10, 18),
      spotId: 'banda',
      spotName: 'Kepulauan Banda',
      maxDepthM: 18,
      bottomTimeMin: 45,
      notes: '  Arus tenang  ',
    );

    expect(entry.seq, 1);
    expect(entry.prevHash, genesisHash);
    expect(entry.notes, 'Arus tenang');
    expect(entry.diveDate, '2026-10-18');
    expect(entry.createdAt, '2026-10-18T03:00:00.000Z');
    expect(entry.hash, 'eeac80dda6e9185272ac5e61deeb0c43d556fcab718571d4d1dd85775273592d');
  });

  test('catatan berikutnya bernomor naik dan membawa hash catatan sebelumnya', () async {
    await _addTwo(service);
    final entries = await service.entries(1);

    expect(entries.map((e) => e.seq), [1, 2]);
    expect(entries[1].prevHash, entries[0].hash);
    expect(entries[1].hash, '7559e2d708a7cb9a43c9b16d4e7deced1bdc631613a42cf4228da68ab3b1b415');
  });

  test('tiap pengguna punya rantai sendiri', () async {
    await _addTwo(service, userId: 1);
    await service.addEntry(
      userId: 2,
      diveDate: DateTime(2026, 10, 18),
      spotId: 'komodo',
      spotName: 'Taman Nasional Komodo',
      maxDepthM: 30,
      bottomTimeMin: 40,
      notes: 'Arus kuat | "catatan" \\ miring',
    );

    final userTwo = await service.entries(2);
    expect(userTwo.length, 1);
    expect(userTwo.single.seq, 1);
    expect(userTwo.single.prevHash, genesisHash);
    expect(userTwo.single.hash, '84dc8673dd3f2e8561c12f9a38f279f157119e0bf130dbfced2e40d92a646076');
    expect((await service.entries(1)).length, 2);
  });

  test('verify menyatakan rantai utuh setelah beberapa catatan', () async {
    await _addTwo(service);
    final report = await service.verify(1);
    expect(report.isValid, isTrue);
    expect(report.checked, 2);
  });

  test('simulasi pemalsuan terdeteksi di catatan pertama lalu bisa dipulihkan', () async {
    await _addTwo(service);

    expect(await service.simulateTampering(1), isTrue);
    final broken = await service.verify(1);
    expect(broken.isValid, isFalse);
    expect(broken.brokenSeq, 1);
    expect(broken.problem, ChainProblem.contentMismatch);
    expect((await service.entries(1)).first.notes, endsWith(LogbookService.tamperMarker));

    await service.restoreSimulation(1);
    expect((await service.verify(1)).isValid, isTrue);
    expect((await service.entries(1)).first.notes, 'Arus tenang');
  });

  test('simulasi pemalsuan dua kali tidak menumpuk tanda', () async {
    await _addTwo(service);
    await service.simulateTampering(1);
    await service.simulateTampering(1);

    final notes = (await service.entries(1)).first.notes;
    expect(notes, 'Arus tenang${LogbookService.tamperMarker}');
  });

  test('simulasi pemalsuan pada logbook kosong mengembalikan false', () async {
    expect(await service.simulateTampering(1), isFalse);
  });

  test('catatan yang dihapus dari tengah terdeteksi', () async {
    await _addTwo(service);
    await service.addEntry(
      userId: 1,
      diveDate: DateTime(2026, 10, 20),
      spotId: 'komodo',
      spotName: 'Taman Nasional Komodo',
      maxDepthM: 20,
      bottomTimeMin: 40,
      notes: '',
    );
    repository.removeEntry(1, 2);

    final report = await service.verify(1);
    expect(report.isValid, isFalse);
    expect(report.brokenSeq, 3);
    expect(report.problem, ChainProblem.sequenceGap);
  });

  group('ubah (update)', () {
    test('mengubah isi, mengisi updatedAt, dan rantai tetap utuh', () async {
      await _addTwo(service);
      final updatedService = LogbookService(repository, clock: () => DateTime.utc(2026, 10, 25, 9));

      final updated = await updatedService.updateEntry(
        userId: 1,
        seq: 1,
        diveDate: DateTime(2026, 10, 18),
        spotId: 'banda',
        spotName: 'Kepulauan Banda',
        maxDepthM: 22,
        bottomTimeMin: 48,
        notes: 'Arus berubah',
      );

      expect(updated.seq, 1);
      expect(updated.maxDepthM, 22);
      expect(updated.notes, 'Arus berubah');
      expect(updated.updatedAt, '2026-10-25T09:00:00.000Z');
      expect(updated.createdAt, '2026-10-18T03:00:00.000Z');
      final entries = await service.entries(1);
      expect(entries.length, 2);
      expect(entries[1].prevHash, entries[0].hash);
      expect((await service.verify(1)).isValid, isTrue);
    });

    test('mengubah catatan yang tidak ada ditolak', () async {
      await _addTwo(service);
      expect(
        () => service.updateEntry(
          userId: 1,
          seq: 9,
          diveDate: DateTime(2026, 10, 18),
          spotId: 'banda',
          spotName: 'Kepulauan Banda',
          maxDepthM: 10,
          bottomTimeMin: 30,
          notes: '',
        ),
        throwsA(isA<LogbookException>()),
      );
    });

    test('mengubah tanggal ke sebelum catatan lain menggeser nomor dan rantai tetap utuh', () async {
      await _addTwo(service);

      final moved = await service.updateEntry(
        userId: 1,
        seq: 2,
        diveDate: DateTime(2026, 10, 1),
        spotId: 'raja-ampat',
        spotName: 'Raja Ampat',
        maxDepthM: 25,
        bottomTimeMin: 50,
        notes: 'Manta di cleaning station',
      );

      expect(moved.seq, 1);
      final entries = await service.entries(1);
      expect(entries.map((e) => e.spotId), ['raja-ampat', 'banda']);
      expect(entries.map((e) => e.seq), [1, 2]);
      expect((await service.verify(1)).isValid, isTrue);
    });
  });

  group('hapus (delete)', () {
    test('menghapus catatan menggeser nomor sesudahnya dan rantai tetap utuh', () async {
      await _addTwo(service);
      await service.addEntry(
        userId: 1,
        diveDate: DateTime(2026, 10, 20),
        spotId: 'komodo',
        spotName: 'Taman Nasional Komodo',
        maxDepthM: 20,
        bottomTimeMin: 40,
        notes: 'ketiga',
      );

      await service.deleteEntry(userId: 1, seq: 2);

      final entries = await service.entries(1);
      expect(entries.map((e) => e.notes), ['Arus tenang', 'ketiga']);
      expect(entries.map((e) => e.seq), [1, 2]);
      expect(entries[1].prevHash, entries[0].hash);
      expect((await service.verify(1)).isValid, isTrue);
    });

    test('menghapus semua catatan menghasilkan logbook kosong yang utuh', () async {
      await _addTwo(service);
      await service.deleteEntry(userId: 1, seq: 1);
      await service.deleteEntry(userId: 1, seq: 1);

      expect(await service.entries(1), isEmpty);
      expect((await service.verify(1)).isValid, isTrue);
    });

    test('menghapus catatan yang tidak ada ditolak', () async {
      await _addTwo(service);
      expect(() => service.deleteEntry(userId: 1, seq: 7), throwsA(isA<LogbookException>()));
    });

    test('catatan pengguna lain tidak ikut terhapus', () async {
      await _addTwo(service, userId: 1);
      await _addTwo(service, userId: 2);
      await service.deleteEntry(userId: 1, seq: 1);

      expect((await service.entries(1)).length, 1);
      expect((await service.entries(2)).length, 2);
    });
  });

  group('urutan menurut tanggal (tambah mundur)', () {
    test('catatan bertanggal lebih awal disisipkan di depan dan nomor bergeser', () async {
      await _addTwo(service);
      final inserted = await service.addEntry(
        userId: 1,
        diveDate: DateTime(2026, 10, 5),
        spotId: 'komodo',
        spotName: 'Taman Nasional Komodo',
        maxDepthM: 20,
        bottomTimeMin: 40,
        notes: 'diisi belakangan',
      );

      expect(inserted.seq, 1);
      final entries = await service.entries(1);
      expect(entries.map((e) => e.diveDate), ['2026-10-05', '2026-10-18', '2026-10-19']);
      expect(entries.map((e) => e.seq), [1, 2, 3]);
      expect((await service.verify(1)).isValid, isTrue);
    });

    test('dua penyelaman di hari yang sama tetap urut menurut waktu dibuat', () async {
      var now = DateTime.utc(2026, 10, 18, 3);
      final ticking = LogbookService(repository, clock: () => now);
      await ticking.addEntry(
        userId: 1,
        diveDate: DateTime(2026, 10, 18),
        spotId: 'banda',
        spotName: 'Kepulauan Banda',
        maxDepthM: 18,
        bottomTimeMin: 45,
        notes: 'pagi',
      );
      now = DateTime.utc(2026, 10, 18, 6);
      await ticking.addEntry(
        userId: 1,
        diveDate: DateTime(2026, 10, 18),
        spotId: 'banda',
        spotName: 'Kepulauan Banda',
        maxDepthM: 15,
        bottomTimeMin: 40,
        notes: 'siang',
      );

      expect((await ticking.entries(1)).map((e) => e.notes), ['pagi', 'siang']);
    });
  });

  group('perubahan saat rantai rusak', () {
    test('tambah, ubah, dan hapus ditolak supaya kerusakan tidak tertutupi', () async {
      await _addTwo(service);
      await service.simulateTampering(1);

      await expectLater(
        service.addEntry(
          userId: 1,
          diveDate: DateTime(2026, 10, 21),
          spotId: 'komodo',
          spotName: 'Taman Nasional Komodo',
          maxDepthM: 20,
          bottomTimeMin: 40,
          notes: '',
        ),
        throwsA(isA<LogbookException>().having((e) => e.message, 'message', contains('Perubahan ditolak'))),
      );
      await expectLater(service.deleteEntry(userId: 1, seq: 2), throwsA(isA<LogbookException>()));
      expect((await service.entries(1)).length, 2);
    });

    test('resealChain menerima kondisi sekarang dan membuat rantai utuh lagi', () async {
      await _addTwo(service);
      await service.simulateTampering(1);
      expect((await service.verify(1)).isValid, isFalse);

      await service.resealChain(1);

      expect((await service.verify(1)).isValid, isTrue);
      expect((await service.entries(1)).first.notes, 'Arus tenang${LogbookService.tamperMarker}');
    });
  });

  group('formatIsoDate dan formatDisplayDate', () {
    test('format tanggal', () {
      expect(formatIsoDate(DateTime(2026, 3, 5)), '2026-03-05');
      expect(formatDisplayDate('2026-03-05'), '05-03-2026');
      expect(formatDisplayDate('bukan tanggal'), 'bukan tanggal');
    });
  });

  group('validator form logbook', () {
    test('kedalaman', () {
      expect(validateDepthMeters('18'), isNull);
      expect(validateDepthMeters(' 150 '), isNull);
      expect(validateDepthMeters(''), isNotNull);
      expect(validateDepthMeters('0'), isNotNull);
      expect(validateDepthMeters('151'), isNotNull);
      expect(validateDepthMeters('18,5'), isNotNull);
      expect(validateDepthMeters('abc'), isNotNull);
      expect(validateDepthMeters(null), isNotNull);
    });

    test('lama di dasar', () {
      expect(validateBottomTimeMinutes('45'), isNull);
      expect(validateBottomTimeMinutes('300'), isNull);
      expect(validateBottomTimeMinutes('0'), isNotNull);
      expect(validateBottomTimeMinutes('301'), isNotNull);
      expect(validateBottomTimeMinutes(''), isNotNull);
    });

    test('catatan boleh kosong tapi dibatasi panjangnya', () {
      expect(validateLogNotes(''), isNull);
      expect(validateLogNotes(null), isNull);
      expect(validateLogNotes('a' * 500), isNull);
      expect(validateLogNotes('a' * 501), isNotNull);
    });
  });
}
