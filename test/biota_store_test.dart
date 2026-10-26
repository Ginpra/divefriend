import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:divefriend/core/encounter_grade.dart';
import 'package:divefriend/core/quiz_builder.dart';
import 'package:divefriend/data/seed/spots_seed.dart';
import 'package:divefriend/services/biota_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('undian terakhir tersimpan dan koleksi bertambah hanya untuk biota baru', () async {
    final store = BiotaStore();
    expect(await store.last(1), isNull);

    expect(await store.record(1, const BiotaPick(name: 'Hiu paus', spotName: 'Teluk Cenderawasih')), isTrue);
    expect(await store.record(1, const BiotaPick(name: 'Hiu paus', spotName: 'Teluk Cenderawasih')), isFalse);
    expect(await store.record(1, const BiotaPick(name: 'Penyu', spotName: 'Bunaken')), isTrue);

    expect((await store.last(1))?.name, 'Penyu');
    expect((await store.found(1)).length, 2);
    expect(await store.found(2), isEmpty);
  });

  test('clear menghapus koleksi satu pengguna', () async {
    final store = BiotaStore();
    await store.record(1, const BiotaPick(name: 'Penyu', spotName: 'Bunaken'));
    await store.clear(1);

    expect(await store.last(1), isNull);
    expect(await store.found(1), isEmpty);
  });

  test('countBiota menghitung biota unik di semua spot', () {
    expect(countBiota(spotsSeed), greaterThan(50));
  });

  test('grade terbaik tiap biota tidak turun walau undian berikutnya lebih rendah', () async {
    final store = BiotaStore();
    const key = 'Penyu|Bunaken';
    await store.record(1, const BiotaPick(name: 'Penyu', spotName: 'Bunaken', grade: EncounterGrade.legendaris));
    await store.record(1, const BiotaPick(name: 'Penyu', spotName: 'Bunaken', grade: EncounterGrade.biasa));

    expect((await store.bestGrades(1))[key], EncounterGrade.legendaris);
    // Undian terakhir tetap yang paling baru, jadi gradenya Biasa.
    expect((await store.last(1))?.grade, EncounterGrade.biasa);
  });

  test('data lama tanpa grade dibaca sebagai Biasa', () async {
    SharedPreferences.setMockInitialValues({
      'biota_last_1': ['Penyu', 'Bunaken'],
      'biota_found_1': ['Penyu|Bunaken'],
    });
    final store = BiotaStore();

    expect((await store.last(1))?.grade, EncounterGrade.biasa);
    expect(await store.bestGrades(1), isEmpty);
  });

  test('clear ikut menghapus grade', () async {
    final store = BiotaStore();
    await store.record(1, const BiotaPick(name: 'Penyu', spotName: 'Bunaken', grade: EncounterGrade.epik));
    await store.clear(1);

    expect(await store.bestGrades(1), isEmpty);
  });
}
