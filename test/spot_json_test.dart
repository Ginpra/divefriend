import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/data/remote/spot_json.dart';

/// Baris contoh: bentuknya sama dengan keluaran tabel public.spots di Postgres (kolom array jadi daftar JSON,
/// kolom kosong jadi null), sudah dicek dengan menjalankan supabase/setup_spots.sql di Postgres asli.
Map<String, dynamic> _row({Map<String, dynamic> override = const {}}) {
  return {
    'id': 'raja-ampat',
    'name': 'Raja Ampat',
    'region': 'Papua Barat Daya',
    'level': 'lanjutan',
    'level_basis': 'Estimasi tim berdasarkan sumber.',
    'types': ['scuba'],
    'tagline': 'Surga keanekaragaman hayati laut.',
    'summary': 'Ringkasan panjang.\n\nParagraf kedua.',
    'depth_text': '5 sampai 40 meter',
    'best_season': 'Oktober sampai April',
    'biota': ['manta', 'hiu karpet'],
    'price_idr': 3000000,
    'latitude': -0.2333115,
    'longitude': 130.5,
    'time_zone': 'WIT',
    'sources': ['Sumber A', 'Sumber B'],
    'photo_url': 'https://example.org/foto.jpg',
    'photo_credit': 'Fotografer',
    'photo_license': 'CC BY-SA 4.0',
    'photo_source_url': 'https://example.org/sumber',
    'updated_at': '2026-10-18T10:00:00+00:00',
    ...override,
  };
}

void main() {
  test('baris lengkap diubah jadi Spot dengan semua kolom', () {
    final spot = spotFromJson(_row());

    expect(spot.id, 'raja-ampat');
    expect(spot.level, SpotLevel.lanjutan);
    expect(spot.types, [SpotType.scuba]);
    expect(spot.summary, 'Ringkasan panjang.\n\nParagraf kedua.');
    expect(spot.biota, ['manta', 'hiu karpet']);
    expect(spot.priceEstimateIdr, 3000000);
    expect(spot.latitude, -0.2333115);
    expect(spot.longitude, 130.5);
    expect(spot.timeZoneLabel, 'WIT');
    expect(spot.sources, ['Sumber A', 'Sumber B']);
    expect(spot.photo?.url, 'https://example.org/foto.jpg');
    expect(spot.photo?.credit, 'Fotografer');
    expect(spot.photo?.license, 'CC BY-SA 4.0');
  });

  test('kolom opsional yang null menjadi null atau daftar kosong', () {
    final spot = spotFromJson(_row(override: {
      'depth_text': null,
      'best_season': null,
      'biota': null,
      'price_idr': null,
      'latitude': null,
      'longitude': null,
      'time_zone': null,
      'photo_url': null,
      'photo_credit': null,
    }));

    expect(spot.depthText, isNull);
    expect(spot.biota, isEmpty);
    expect(spot.priceEstimateIdr, isNull);
    expect(spot.latitude, isNull);
    expect(spot.timeZoneLabel, isNull);
    expect(spot.photo, isNull);
  });

  test('angka bulat untuk koordinat tetap terbaca sebagai double', () {
    final spot = spotFromJson(_row(override: {'latitude': 2, 'longitude': 120, 'price_idr': 1500000.0}));
    expect(spot.latitude, 2.0);
    expect(spot.longitude, 120.0);
    expect(spot.priceEstimateIdr, 1500000);
  });

  test('dua jenis (scuba dan snorkeling) terbaca berurutan', () {
    final spot = spotFromJson(_row(override: {'types': ['scuba', 'snorkeling']}));
    expect(spot.types, [SpotType.scuba, SpotType.snorkeling]);
  });

  group('baris rusak melempar FormatException', () {
    test('level tidak dikenal', () {
      expect(() => spotFromJson(_row(override: {'level': 'ahli'})), throwsFormatException);
    });

    test('jenis tidak dikenal atau kosong', () {
      expect(() => spotFromJson(_row(override: {'types': ['terbang']})), throwsFormatException);
      expect(() => spotFromJson(_row(override: {'types': []})), throwsFormatException);
      expect(() => spotFromJson(_row(override: {'types': null})), throwsFormatException);
    });

    test('sumber kosong (aturan proyek: setiap data wajib bersumber)', () {
      expect(() => spotFromJson(_row(override: {'sources': []})), throwsFormatException);
      expect(() => spotFromJson(_row(override: {'sources': null})), throwsFormatException);
    });

    test('kolom wajib hilang atau bukan teks', () {
      expect(() => spotFromJson(_row(override: {'name': null})), throwsFormatException);
      expect(() => spotFromJson(_row(override: {'id': ''})), throwsFormatException);
      expect(() => spotFromJson(_row(override: {'summary': 5})), throwsFormatException);
    });

    test('daftar berisi bukan teks', () {
      expect(() => spotFromJson(_row(override: {'biota': ['ok', 3]})), throwsFormatException);
      expect(() => spotFromJson(_row(override: {'sources': 'bukan daftar'})), throwsFormatException);
    });
  });
}
