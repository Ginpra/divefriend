import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/data/repositories/dummy_spot_repository.dart';

void main() {
  final repository = DummySpotRepository(simulatedDelay: Duration.zero);

  test('tanpa filter mengembalikan semua spot', () async {
    final spots = await repository.getSpots();
    expect(spots, isNotEmpty);
  });

  test('filter level hanya mengembalikan level itu', () async {
    final spots = await repository.getSpots(level: SpotLevel.lanjutan);
    expect(spots, isNotEmpty);
    expect(spots.every((spot) => spot.level == SpotLevel.lanjutan), isTrue);
  });

  test('pencarian tidak peka huruf besar/kecil dan mencakup wilayah', () async {
    final byName = await repository.getSpots(query: 'bUnAkEn');
    expect(byName.map((spot) => spot.id), contains('bunaken'));

    final byRegion = await repository.getSpots(query: 'bali');
    expect(byRegion.map((spot) => spot.id), contains('tulamben'));
  });

  test('pencarian tanpa hasil mengembalikan daftar kosong', () async {
    final spots = await repository.getSpots(query: 'zzzzzz');
    expect(spots, isEmpty);
  });
}
