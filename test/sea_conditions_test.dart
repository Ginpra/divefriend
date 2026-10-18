import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:divefriend/data/models/sea_conditions.dart';
import 'package:divefriend/services/api_failure.dart';
import 'package:divefriend/services/marine_service.dart';

/// CATATAN: contoh respons ini disusun dari dokumentasi Open-Meteo (bentuk "daily" berisi
/// array time dan array nilai) dan kebiasaan Open-Meteo untuk "current" (objek berisi time,
/// interval, dan nilai). Ini bukan salinan respons asli, jadi parser sengaja dibuat longgar.
const String _sampleJson = '''
{
  "latitude": 1.7, "longitude": 124.6, "generationtime_ms": 0.2,
  "utc_offset_seconds": 28800, "timezone": "Asia/Makassar",
  "current_units": {"time": "iso8601", "interval": "seconds", "wave_height": "m"},
  "current": {"time": "2026-10-18T10:00", "interval": 900, "wave_height": 0.62},
  "daily_units": {"time": "iso8601", "wave_height_max": "m"},
  "daily": {"time": ["2026-10-18"], "wave_height_max": [0.84]}
}
''';

void main() {
  group('SeaConditions.fromJson', () {
    test('membaca tinggi gelombang saat ini dan tertinggi hari ini', () {
      final conditions = SeaConditions.fromJson({
        'current': {'time': '2026-10-18T10:00', 'wave_height': 0.62},
        'daily': {
          'time': ['2026-10-18'],
          'wave_height_max': [0.84],
        },
      });
      expect(conditions.currentWaveHeightM, 0.62);
      expect(conditions.maxWaveHeightTodayM, 0.84);
      expect(conditions.hasData, isTrue);
    });

    test('angka bulat (int) tetap terbaca', () {
      final conditions = SeaConditions.fromJson({
        'current': {'wave_height': 1},
        'daily': {
          'wave_height_max': [2],
        },
      });
      expect(conditions.currentWaveHeightM, 1.0);
      expect(conditions.maxWaveHeightTodayM, 2.0);
    });

    test('nilai null dari model (titik di darat) berarti tidak ada data', () {
      final conditions = SeaConditions.fromJson({
        'current': {'wave_height': null},
        'daily': {
          'wave_height_max': [null],
        },
      });
      expect(conditions.hasData, isFalse);
    });

    test('bagian yang hilang atau bentuknya aneh tidak membuat error', () {
      expect(SeaConditions.fromJson({}).hasData, isFalse);
      expect(
        SeaConditions.fromJson({'current': 5, 'daily': {'wave_height_max': []}}).hasData,
        isFalse,
      );
      expect(
        SeaConditions.fromJson({
          'daily': {
            'wave_height_max': [0.5],
          },
        }).maxWaveHeightTodayM,
        0.5,
      );
    });
  });

  group('OpenMeteoMarineService', () {
    test('meminta alamat marine dengan koordinat dan variabel yang benar', () async {
      late Uri requested;
      final service = OpenMeteoMarineService(
        MockClient((request) async {
          requested = request.url;
          return http.Response(_sampleJson, 200);
        }),
      );

      final conditions = await service.fetchToday(latitude: 1.667, longitude: 124.65);

      expect(requested.host, 'marine-api.open-meteo.com');
      expect(requested.path, '/v1/marine');
      expect(requested.queryParameters['latitude'], '1.667');
      expect(requested.queryParameters['longitude'], '124.65');
      expect(requested.queryParameters['current'], 'wave_height');
      expect(requested.queryParameters['daily'], 'wave_height_max');
      expect(requested.queryParameters['timezone'], 'auto');
      expect(requested.queryParameters['forecast_days'], '1');
      expect(conditions.currentWaveHeightM, 0.62);
      expect(conditions.maxWaveHeightTodayM, 0.84);
    });

    test('koordinat negatif ikut terkirim apa adanya', () async {
      late Uri requested;
      final service = OpenMeteoMarineService(
        MockClient((request) async {
          requested = request.url;
          return http.Response(_sampleJson, 200);
        }),
      );
      await service.fetchToday(latitude: -8.54333, longitude: 119.48944);
      expect(requested.queryParameters['latitude'], '-8.54333');
      expect(requested.queryParameters['longitude'], '119.48944');
    });

    test('status 400 dianggap masalah layanan', () async {
      final service = OpenMeteoMarineService(
        MockClient((request) async => http.Response('{"error":true,"reason":"x"}', 400)),
      );
      await expectLater(
        service.fetchToday(latitude: 0, longitude: 0),
        throwsA(
          isA<ApiFailure>().having((e) => e.kind, 'kind', ApiFailureKind.server),
        ),
      );
    });

    test('gagal terhubung dianggap offline', () async {
      final service = OpenMeteoMarineService(
        MockClient((request) async => throw http.ClientException('putus')),
      );
      await expectLater(
        service.fetchToday(latitude: 0, longitude: 0),
        throwsA(
          isA<ApiFailure>().having((e) => e.kind, 'kind', ApiFailureKind.offline),
        ),
      );
    });

    test('isi bukan objek JSON dianggap data rusak', () async {
      final service = OpenMeteoMarineService(
        MockClient((request) async => http.Response('halaman html', 200)),
      );
      await expectLater(
        service.fetchToday(latitude: 0, longitude: 0),
        throwsA(
          isA<ApiFailure>().having((e) => e.kind, 'kind', ApiFailureKind.badData),
        ),
      );
    });
  });
}
