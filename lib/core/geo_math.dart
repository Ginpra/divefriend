import 'dart:math' as math;

import 'package:divefriend/core/formatters.dart';

/// Jari-jari rata-rata bumi dalam meter (nilai standar untuk rumus haversine).
const double _earthRadiusMeters = 6371008.8;

double _toRadians(double degrees) => degrees * math.pi / 180;

double _toDegrees(double radians) => radians * 180 / math.pi;

/// Jarak garis lurus di permukaan bumi antara dua titik (rumus haversine), dalam meter.
double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
  final deltaLat = _toRadians(lat2 - lat1);
  final deltaLon = _toRadians(lon2 - lon1);
  final a = math.pow(math.sin(deltaLat / 2), 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.pow(math.sin(deltaLon / 2), 2);
  return 2 * _earthRadiusMeters * math.asin(math.sqrt(a));
}

/// Arah awal dari titik 1 menuju titik 2 dalam derajat searah jarum jam dari utara sejati (0 sampai 360).
double bearingDegrees(double lat1, double lon1, double lat2, double lon2) {
  final phi1 = _toRadians(lat1);
  final phi2 = _toRadians(lat2);
  final deltaLon = _toRadians(lon2 - lon1);
  final y = math.sin(deltaLon) * math.cos(phi2);
  final x = math.cos(phi1) * math.sin(phi2) -
      math.sin(phi1) * math.cos(phi2) * math.cos(deltaLon);
  return (_toDegrees(math.atan2(y, x)) + 360) % 360;
}

/// Mengubah sudut apa pun ke rentang 0 sampai kurang dari 360.
double normalizeDegrees(double degrees) => ((degrees % 360) + 360) % 360;

/// Jarak untuk dibaca manusia: "850 m", "1,2 km", "427 km", "1.235 km".
String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  final km = meters / 1000;
  if (km < 10) return '${formatNumber(km, decimals: 1)} km';
  return '${formatNumber(km)} km';
}

/// Arah mata angin delapan penjuru dengan singkatan Indonesia:
/// U utara, TL timur laut, T timur, TG tenggara, S selatan, BD barat daya, B barat, BL barat laut.
String cardinalLabel(double degrees) {
  const labels = ['U', 'TL', 'T', 'TG', 'S', 'BD', 'B', 'BL'];
  final index = (normalizeDegrees(degrees) / 45).round() % 8;
  return labels[index];
}
