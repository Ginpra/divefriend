import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/data/seed/access_points.dart';
import 'package:divefriend/data/seed/spots_seed.dart';

void main() {
  test('setiap spot punya pintu masuk dan tidak ada pintu masuk yatim', () {
    final spotIds = spotsSeed.map((spot) => spot.id).toSet();
    expect(accessPointsBySpotId.keys.toSet(), spotIds);
  });

  test('semua pintu masuk lengkap dan bersumber', () {
    accessPointsBySpotId.forEach((id, accessPoint) {
      expect(accessPoint.name.trim(), isNotEmpty, reason: '$id: nama kosong');
      expect(accessPoint.mapsQuery.trim(), isNotEmpty, reason: '$id: tujuan peta kosong');
      expect(accessPoint.steps.trim(), isNotEmpty, reason: '$id: langkah kosong');
      expect(accessPoint.sources, isNotEmpty, reason: '$id: sumber kosong');
    });
  });

  test('teks yang tampil ke pengguna tidak memakai titik koma', () {
    accessPointsBySpotId.forEach((id, accessPoint) {
      expect(accessPoint.name.contains(';'), isFalse, reason: '$id: nama');
      expect(accessPoint.steps.contains(';'), isFalse, reason: '$id: langkah');
    });
  });

  test('tujuan rute tidak memakai titik pusat kawasan yang ada di laut', () {
    for (final spot in spotsSeed) {
      final accessPoint = accessPointsBySpotId[spot.id]!;
      final centerPoint = '${spot.latitude},${spot.longitude}';
      expect(accessPoint.mapsQuery, isNot(centerPoint), reason: '${spot.id}: tujuan sama dengan titik pusat spot');
    }
  });
}
