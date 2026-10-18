import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/data/seed/spots_seed.dart';

/// Penjaga mutu data: tes ini gagal kalau ada spot tanpa sumber,
/// koordinat di luar jangkauan, foto tanpa atribusi, atau teks memakai tanda titik koma.
void main() {
  test('jumlah spot minimal 15', () {
    expect(spotsSeed.length, greaterThanOrEqualTo(15));
  });

  test('id spot unik', () {
    final ids = spotsSeed.map((spot) => spot.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('setiap spot punya nama, wilayah, jenis, kalimat pembuka, deskripsi, dan sumber', () {
    for (final spot in spotsSeed) {
      expect(spot.name, isNotEmpty, reason: spot.id);
      expect(spot.region, isNotEmpty, reason: spot.id);
      expect(spot.types, isNotEmpty, reason: spot.id);
      expect(spot.tagline, isNotEmpty, reason: spot.id);
      expect(spot.summary.length, greaterThan(300), reason: '${spot.id}: deskripsi terlalu pendek');
      expect(spot.sources, isNotEmpty, reason: spot.id);
    }
  });

  test('koordinat (jika ada) berpasangan dan berada di wilayah Indonesia', () {
    for (final spot in spotsSeed) {
      final latitude = spot.latitude;
      final longitude = spot.longitude;
      expect(latitude == null, longitude == null, reason: '${spot.id}: lat/lon harus berpasangan');
      if (latitude != null && longitude != null) {
        expect(latitude, inInclusiveRange(-12, 7), reason: spot.id);
        expect(longitude, inInclusiveRange(94, 142), reason: spot.id);
      }
    }
  });

  test('foto punya alamat https, dan kalau lisensi diisi maka kredit wajib diisi', () {
    for (final spot in spotsSeed) {
      final photo = spot.photo;
      if (photo == null) continue;
      expect(photo.url, startsWith('https://'), reason: spot.id);
      if (photo.license != null) {
        expect(photo.credit, isNotNull, reason: '${spot.id}: lisensi tanpa kredit');
      }
    }
  });

  test('setiap spot lengkap: kedalaman, musim, biota, dan foto terisi', () {
    for (final spot in spotsSeed) {
      expect(spot.depthText, isNotNull, reason: '${spot.id}: kedalaman kosong');
      expect(spot.bestSeason, isNotNull, reason: '${spot.id}: musim kosong');
      expect(spot.biota, isNotEmpty, reason: '${spot.id}: biota kosong');
      expect(spot.photo, isNotNull, reason: '${spot.id}: foto kosong');
    }
  });

  test('setiap spot punya harga paket simulasi kelipatan 100 ribu rupiah', () {
    for (final spot in spotsSeed) {
      final price = spot.priceEstimateIdr;
      expect(price, isNotNull, reason: '${spot.id}: harga simulasi kosong');
      expect(price! % 100000, 0, reason: '${spot.id}: harga $price bukan kelipatan 100 ribu');
    }
  });

  test('angka harga (jika ada) harus positif', () {
    for (final spot in spotsSeed) {
      final price = spot.priceEstimateIdr;
      if (price != null) expect(price, greaterThan(0), reason: spot.id);
    }
  });

  test('teks untuk pengguna tidak memakai tanda titik koma', () {
    for (final spot in spotsSeed) {
      final texts = [
        spot.name,
        spot.region,
        spot.tagline,
        spot.summary,
        spot.levelBasis,
        spot.depthText ?? '',
        spot.bestSeason ?? '',
        ...spot.biota,
        ...spot.sources,
      ];
      for (final text in texts) {
        expect(text.contains(';'), isFalse, reason: '${spot.id}: "$text"');
      }
    }
  });
}
