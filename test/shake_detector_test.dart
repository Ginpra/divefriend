import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/core/shake_detector.dart';
import 'package:divefriend/core/vec3.dart';

void main() {
  final start = DateTime(2026, 10, 18, 12);
  const still = Vec3(0, 0, 9.8);
  const strongJolt = Vec3(0, 0, 40);

  DateTime at(int milliseconds) => start.add(Duration(milliseconds: milliseconds));

  test('HP diam atau digerakkan pelan tidak dianggap goyang', () {
    final detector = ShakeDetector();
    for (var i = 0; i < 50; i++) {
      expect(detector.addSample(still, at(i * 50)), isFalse);
    }
    expect(detector.addSample(const Vec3(5, 5, 12), at(3000)), isFalse);
  });

  test('satu hentakan saja belum cukup', () {
    final detector = ShakeDetector();
    expect(detector.addSample(strongJolt, at(0)), isFalse);
    expect(detector.addSample(still, at(50)), isFalse);
  });

  test('dua hentakan dalam waktu singkat dianggap goyang', () {
    final detector = ShakeDetector();
    expect(detector.addSample(strongJolt, at(0)), isFalse);
    expect(detector.addSample(strongJolt, at(200)), isTrue);
  });

  test('sampel beruntun dari satu hentakan yang sama tidak dihitung dua kali', () {
    final detector = ShakeDetector();
    expect(detector.addSample(strongJolt, at(0)), isFalse);
    expect(detector.addSample(strongJolt, at(50)), isFalse);
  });

  test('hentakan yang terlalu berjauhan tidak dihitung satu goyangan', () {
    final detector = ShakeDetector();
    expect(detector.addSample(strongJolt, at(0)), isFalse);
    expect(detector.addSample(strongJolt, at(1000)), isFalse);
  });

  test('setelah terdeteksi ada jeda sebelum goyangan berikutnya', () {
    final detector = ShakeDetector();
    detector.addSample(strongJolt, at(0));
    expect(detector.addSample(strongJolt, at(200)), isTrue);

    expect(detector.addSample(strongJolt, at(400)), isFalse);
    expect(detector.addSample(strongJolt, at(600)), isFalse);

    expect(detector.addSample(strongJolt, at(1500)), isFalse);
    expect(detector.addSample(strongJolt, at(1700)), isTrue);
  });
}
