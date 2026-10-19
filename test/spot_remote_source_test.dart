import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:divefriend/data/remote/spot_remote_source.dart';
import 'package:divefriend/data/remote/supabase_config.dart';
import 'package:divefriend/services/api_failure.dart';

const SupabaseConfig _config = SupabaseConfig(
  url: 'https://abc123.supabase.co',
  apiKey: 'sb_publishable_contoh',
);

Map<String, dynamic> _row(String id, String name) {
  return {
    'id': id,
    'name': name,
    'region': 'Wilayah',
    'level': 'pemula',
    'level_basis': 'Estimasi tim.',
    'types': ['scuba', 'snorkeling'],
    'tagline': 'Tagline.',
    'summary': 'Ringkasan.',
    'depth_text': null,
    'best_season': null,
    'biota': ['penyu'],
    'price_idr': 1200000,
    'latitude': -5.8,
    'longitude': 110.4,
    'time_zone': 'WIB',
    'sources': ['Sumber'],
    'photo_url': null,
    'photo_credit': null,
    'photo_license': null,
    'photo_source_url': null,
    'updated_at': '2026-10-18T10:00:00+00:00',
  };
}

Matcher _failureOf(ApiFailureKind kind) {
  return throwsA(isA<ApiFailure>().having((error) => error.kind, 'kind', kind));
}

void main() {
  test('meminta tabel spots dengan header apikey SAJA (tanpa Authorization)', () async {
    late http.Request captured;
    final source = SupabaseSpotSource(
      MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode([_row('a', 'Alfa'), _row('b', 'Bravo')]), 200);
      }),
      _config,
    );

    final spots = await source.fetchSpots();

    expect(captured.url.host, 'abc123.supabase.co');
    expect(captured.url.path, '/rest/v1/spots');
    expect(captured.url.queryParameters['select'], '*');
    expect(captured.url.queryParameters['order'], 'name.asc');
    expect(captured.headers['apikey'], 'sb_publishable_contoh');
    expect(captured.headers.containsKey('Authorization'), isFalse);
    expect(captured.headers.containsKey('authorization'), isFalse);
    expect(spots.map((spot) => spot.id), ['a', 'b']);
    expect(spots.first.priceEstimateIdr, 1200000);
  });

  test('daftar kosong dikembalikan apa adanya (keputusannya ada di layanan sinkron)', () async {
    final source = SupabaseSpotSource(
      MockClient((request) async => http.Response('[]', 200)),
      _config,
    );
    expect(await source.fetchSpots(), isEmpty);
  });

  test('status 401 atau 404 dianggap masalah layanan', () async {
    for (final status in [401, 404, 500]) {
      final source = SupabaseSpotSource(
        MockClient((request) async => http.Response('{"message":"x"}', status)),
        _config,
      );
      await expectLater(source.fetchSpots(), _failureOf(ApiFailureKind.server));
    }
  });

  test('gagal terhubung dianggap offline', () async {
    final source = SupabaseSpotSource(
      MockClient((request) async => throw http.ClientException('putus')),
      _config,
    );
    await expectLater(source.fetchSpots(), _failureOf(ApiFailureKind.offline));
  });

  test('isi bukan daftar atau bukan JSON dianggap data rusak', () async {
    for (final body in ['{"a":1}', 'bukan json', 'null']) {
      final source = SupabaseSpotSource(
        MockClient((request) async => http.Response(body, 200)),
        _config,
      );
      await expectLater(source.fetchSpots(), _failureOf(ApiFailureKind.badData));
    }
  });

  test('satu baris rusak membatalkan seluruh pengambilan', () async {
    final broken = _row('b', 'Bravo')..['level'] = 'ahli';
    final source = SupabaseSpotSource(
      MockClient((request) async => http.Response(jsonEncode([_row('a', 'Alfa'), broken]), 200)),
      _config,
    );
    await expectLater(source.fetchSpots(), _failureOf(ApiFailureKind.badData));
  });

  test('baris yang bukan objek dianggap data rusak', () async {
    final source = SupabaseSpotSource(
      MockClient((request) async => http.Response('[1, 2]', 200)),
      _config,
    );
    await expectLater(source.fetchSpots(), _failureOf(ApiFailureKind.badData));
  });
}
