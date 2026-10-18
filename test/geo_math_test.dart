import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/core/geo_math.dart';

void main() {
  group('distanceMeters', () {
    test('satu derajat lintang sekitar 111,2 km', () {
      expect(distanceMeters(0, 0, 1, 0), closeTo(111195, 5));
    });

    test('satu derajat bujur di khatulistiwa sama dengan satu derajat lintang', () {
      expect(distanceMeters(0, 0, 0, 1), closeTo(111195, 5));
    });

    test('titik yang sama berjarak nol dan jarak bersifat simetris', () {
      expect(distanceMeters(-6.2, 106.8, -6.2, 106.8), 0);
      final forward = distanceMeters(-6.2088, 106.8456, -7.7956, 110.3695);
      final backward = distanceMeters(-7.7956, 110.3695, -6.2088, 106.8456);
      expect(forward, closeTo(backward, 1e-6));
    });

    test('Jakarta ke Yogyakarta sekitar 427 km (hitungan haversine)', () {
      expect(
        distanceMeters(-6.2088, 106.8456, -7.7956, 110.3695),
        closeTo(427058, 200),
      );
    });
  });

  group('bearingDegrees', () {
    test('empat arah mata angin dari khatulistiwa', () {
      expect(bearingDegrees(0, 0, 1, 0), closeTo(0, 1e-6));
      expect(bearingDegrees(0, 0, 0, 1), closeTo(90, 1e-6));
      expect(bearingDegrees(0, 0, -1, 0), closeTo(180, 1e-6));
      expect(bearingDegrees(0, 0, 0, -1), closeTo(270, 1e-6));
    });

    test('timur laut dan Jakarta ke Yogyakarta mengarah tenggara', () {
      expect(bearingDegrees(0, 0, 1, 1), closeTo(44.996, 0.01));
      expect(bearingDegrees(-6.2088, 106.8456, -7.7956, 110.3695), closeTo(114.61, 0.05));
    });
  });

  group('pembantu tampilan', () {
    test('normalizeDegrees', () {
      expect(normalizeDegrees(0), 0);
      expect(normalizeDegrees(360), 0);
      expect(normalizeDegrees(-90), 270);
      expect(normalizeDegrees(725), 5);
    });

    test('formatDistance memilih meter atau kilometer', () {
      expect(formatDistance(850), '850 m');
      expect(formatDistance(999.4), '999 m');
      expect(formatDistance(1234), '1,2 km');
      expect(formatDistance(15600), '16 km');
      expect(formatDistance(1234567), '1.235 km');
    });

    test('cardinalLabel delapan penjuru', () {
      expect(cardinalLabel(0), 'U');
      expect(cardinalLabel(44), 'TL');
      expect(cardinalLabel(90), 'T');
      expect(cardinalLabel(135), 'TG');
      expect(cardinalLabel(180), 'S');
      expect(cardinalLabel(202.4), 'S');
      expect(cardinalLabel(202.6), 'BD');
      expect(cardinalLabel(270), 'B');
      expect(cardinalLabel(315), 'BL');
      expect(cardinalLabel(359), 'U');
    });
  });
}
