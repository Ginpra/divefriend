import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/core/compass_math.dart';
import 'package:divefriend/core/shake_detector.dart';
import 'package:divefriend/core/vec3.dart';

double _dot(List<double> a, List<double> b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];

/// Membuat data sensor palsu untuk HP yang bagian atasnya menghadap [headingDeg] dan
/// dimiringkan [pitchDeg] derajat (bagian atas naik). Dunia memakai sumbu timur, utara, atas.
/// Medan magnet bumi dibuat 30 ke utara dan 40 ke bawah (mirip belahan bumi utara), gravitasi
/// yang terbaca akselerometer menunjuk ke atas (reaksi terhadap gravitasi).
({Vec3 gravity, Vec3 magnetic}) _simulateSensors(double headingDeg, double pitchDeg) {
  final psi = headingDeg * math.pi / 180;
  final theta = pitchDeg * math.pi / 180;
  final x = [math.cos(psi), -math.sin(psi), 0.0];
  final yFlat = [math.sin(psi), math.cos(psi), 0.0];
  const z = [0.0, 0.0, 1.0];
  final y = [
    for (var i = 0; i < 3; i++) yFlat[i] * math.cos(theta) + z[i] * math.sin(theta),
  ];
  final zTilted = [
    for (var i = 0; i < 3; i++) z[i] * math.cos(theta) - yFlat[i] * math.sin(theta),
  ];
  const up = [0.0, 0.0, 1.0];
  const earthField = [0.0, 30.0, -40.0];
  return (
    gravity: Vec3(
      standardGravity * _dot(up, x),
      standardGravity * _dot(up, y),
      standardGravity * _dot(up, zTilted),
    ),
    magnetic: Vec3(_dot(earthField, x), _dot(earthField, y), _dot(earthField, zTilted)),
  );
}

void main() {
  group('headingDegrees', () {
    test('HP rata menghadap utara, timur, selatan, barat', () {
      expect(headingDegrees(const Vec3(0, 0, 9.8), const Vec3(0, 30, -40)), closeTo(0, 1e-9));
      expect(headingDegrees(const Vec3(0, 0, 9.8), const Vec3(-30, 0, -40)), closeTo(90, 1e-9));
      expect(headingDegrees(const Vec3(0, 0, 9.8), const Vec3(0, -30, -40)), closeTo(180, 1e-9));
      expect(headingDegrees(const Vec3(0, 0, 9.8), const Vec3(30, 0, -40)), closeTo(270, 1e-9));
    });

    test('tetap benar untuk berbagai arah dan kemiringan HP', () {
      for (final heading in [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0]) {
        for (final pitch in [0.0, 30.0, 60.0]) {
          final sensors = _simulateSensors(heading, pitch);
          final result = headingDegrees(sensors.gravity, sensors.magnetic);
          expect(result, isNotNull);
          final difference = ((result! - heading + 180) % 360) - 180;
          expect(difference.abs(), lessThan(1e-6), reason: 'arah $heading, miring $pitch');
        }
      }
    });

    test('data tidak layak (jatuh bebas atau medan nol) menghasilkan null', () {
      expect(headingDegrees(const Vec3(0, 0, 0), const Vec3(0, 30, -40)), isNull);
      expect(headingDegrees(const Vec3(0, 0, 9.8), const Vec3(0, 0, 0)), isNull);
    });
  });

  group('smoothVec3', () {
    test('sampel pertama dipakai apa adanya', () {
      final result = smoothVec3(null, const Vec3(1, 2, 3));
      expect(result.x, 1);
      expect(result.z, 3);
    });

    test('sampel berikutnya hanya ikut sebagian', () {
      final result = smoothVec3(const Vec3(0, 0, 0), const Vec3(10, -10, 5), alpha: 0.2);
      expect(result.x, closeTo(2, 1e-9));
      expect(result.y, closeTo(-2, 1e-9));
      expect(result.z, closeTo(1, 1e-9));
    });
  });

  group('Vec3', () {
    test('cross dan length', () {
      final c = const Vec3(1, 0, 0).cross(const Vec3(0, 1, 0));
      expect((c.x, c.y, c.z), (0.0, 0.0, 1.0));
      expect(const Vec3(3, 4, 0).length, 5);
    });
  });
}
