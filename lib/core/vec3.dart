import 'dart:math' as math;

/// Vektor tiga sumbu (x, y, z) untuk data sensor. Hanya berisi operasi yang dipakai kompas dan deteksi goyang.
class Vec3 {
  const Vec3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  Vec3 operator +(Vec3 other) => Vec3(x + other.x, y + other.y, z + other.z);

  Vec3 operator -(Vec3 other) => Vec3(x - other.x, y - other.y, z - other.z);

  Vec3 operator *(double factor) => Vec3(x * factor, y * factor, z * factor);

  double get lengthSquared => x * x + y * y + z * z;

  double get length => math.sqrt(lengthSquared);

  /// Hasil kali silang: vektor yang tegak lurus terhadap kedua vektor.
  Vec3 cross(Vec3 other) {
    return Vec3(
      y * other.z - z * other.y,
      z * other.x - x * other.z,
      x * other.y - y * other.x,
    );
  }
}
