import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/data/models/geo_point.dart';
import 'package:divefriend/services/map_launcher.dart';

void main() {
  test('mapsUri memakai format Google Maps URLs dengan lintang dan bujur', () {
    final uri = mapsUri(const GeoPoint(-8.54333, 119.48944));

    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/search/');
    expect(uri.queryParameters['api'], '1');
    expect(uri.queryParameters['query'], '-8.54333,119.48944');
  });

  group('directionsUri', () {
    test('tanpa origin: rute dimulai dari lokasi pengguna', () {
      final uri = directionsUri(destination: 'Pelabuhan Kartini, Jepara');

      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters['destination'], 'Pelabuhan Kartini, Jepara');
      expect(uri.queryParameters.containsKey('origin'), isFalse);
    });

    test('dengan origin: titik awal ikut dikirim', () {
      final uri = directionsUri(origin: 'Yogyakarta', destination: 'Bandara Komodo, Labuan Bajo');

      expect(uri.queryParameters['origin'], 'Yogyakarta');
      expect(uri.queryParameters['destination'], 'Bandara Komodo, Labuan Bajo');
    });

    test('tujuan berupa koordinat tetap utuh', () {
      final uri = directionsUri(destination: '-8.27441,115.5949');
      expect(uri.queryParameters['destination'], '-8.27441,115.5949');
    });
  });
}
