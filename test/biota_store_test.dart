import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
