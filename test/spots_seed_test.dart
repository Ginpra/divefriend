import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/data/seed/spots_seed.dart';

/// Penjaga mutu data: tes ini gagal kalau ada spot tanpa sumber,
/// koordinat di luar jangkauan, atau foto tanpa atribusi.
void main() {
  test('id spot unik', () {
    final ids = spotsSeed.map((spot) => spot.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('setiap spot punya nama, wilayah, jenis, dan minimal satu sumber', () {
    for (final spot in spotsSeed) {
      expect(spot.name, isNotEmpty, reason: spot.id);
      expect(spot.region, isNotEmpty, reason: spot.id);
      expect(spot.types, isNotEmpty, reason: spot.id);
      expect(spot.sources, isNotEmpty, reason: spot.id);
    }
  });

  test('koordinat (jika ada) berada di rentang bumi yang valid dan lengkap', () {
    for (final spot in spotsSeed) {
      final latitude = spot.latitude;
      final longitude = spot.longitude;
      expect(latitude == null, longitude == null, reason: '${spot.id}: lat/lon harus berpasangan');
      if (latitude != null && longitude != null) {
        expect(latitude, inInclusiveRange(-90, 90), reason: spot.id);
        expect(longitude, inInclusiveRange(-180, 180), reason: spot.id);
      }
    }
  });

  test('koordinat spot berada di wilayah Indonesia (sanity check kasar)', () {
    for (final spot in spotsSeed) {
      final latitude = spot.latitude;
      final longitude = spot.longitude;
      if (latitude == null || longitude == null) continue;
      expect(latitude, inInclusiveRange(-12, 7), reason: spot.id);
      expect(longitude, inInclusiveRange(94, 142), reason: spot.id);
    }
  });

  test('foto (jika ada) wajib memuat atribusi lengkap', () {
    for (final spot in spotsSeed) {
      final photo = spot.photo;
      if (photo == null) continue;
      expect(photo.url, startsWith('https://'), reason: spot.id);
      expect(photo.credit, isNotEmpty, reason: spot.id);
      expect(photo.license, isNotEmpty, reason: spot.id);
      expect(photo.sourceUrl, startsWith('https://'), reason: spot.id);
    }
  });

  test('angka opsional tidak boleh nol atau negatif tanpa arti', () {
    for (final spot in spotsSeed) {
      final depth = spot.depthMeters;
      if (depth != null) expect(depth, greaterThan(0), reason: spot.id);
      final price = spot.priceEstimateIdr;
      if (price != null) expect(price, greaterThan(0), reason: spot.id);
    }
  });
}
