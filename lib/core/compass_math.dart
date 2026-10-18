import 'dart:math' as math;

import 'package:divefriend/core/geo_math.dart';
import 'package:divefriend/core/vec3.dart';

/// Arah yang ditunjuk bagian atas HP, dalam derajat dari utara magnetik (0 sampai 360).
///
/// Memakai dua sensor sekaligus: akselerometer ([gravity], untuk tahu mana arah "bawah")
/// dan magnetometer ([magnetic]). Dengan begitu hasilnya tetap benar walau HP agak miring,
/// tidak harus rata. Caranya sama dengan SensorManager.getRotationMatrix milik Android.
/// Null kalau datanya tidak bisa dipakai (misalnya HP sedang jatuh bebas).
double? headingDegrees(Vec3 gravity, Vec3 magnetic) {
  final east = magnetic.cross(gravity);
  if (east.lengthSquared < 0.1 || gravity.lengthSquared == 0) return null;
  final eastUnit = east * (1 / east.length);
  final down = gravity * (1 / gravity.length);
  final north = down.cross(eastUnit);
  final azimuth = math.atan2(eastUnit.y, north.y);
  return normalizeDegrees(azimuth * 180 / math.pi);
}

/// Penghalus data sensor (low-pass). Nilai baru hanya ikut sebagian ([alpha]), supaya
/// panah tidak bergetar. Sampel pertama dipakai apa adanya.
Vec3 smoothVec3(Vec3? previous, Vec3 sample, {double alpha = 0.2}) {
  if (previous == null) return sample;
  return previous + (sample - previous) * alpha;
}
