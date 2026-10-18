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
