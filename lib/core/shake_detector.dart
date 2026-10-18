import 'package:divefriend/core/vec3.dart';

/// Percepatan gravitasi standar dalam m/s2, untuk mengubah data akselerometer jadi satuan "g".
const double standardGravity = 9.80665;

/// Mendeteksi HP digoyang dari data akselerometer.
/// Satu "hentakan" = percepatan total melewati [thresholdG], dan goyang dianggap terjadi kalau
/// ada [requiredJolts] hentakan dalam [joltWindow]. Setelah terdeteksi ada jeda [cooldown]
/// supaya satu goyangan tidak dihitung berkali-kali. Angka-angkanya nilai awal pilihan tim
/// dan bisa disetel kalau terlalu sensitif atau terlalu susah.
class ShakeDetector {
  ShakeDetector({
    this.thresholdG = 2.7,
    this.requiredJolts = 2,
    this.joltWindow = const Duration(milliseconds: 600),
    this.minJoltGap = const Duration(milliseconds: 100),
    this.cooldown = const Duration(seconds: 1),
  });

  final double thresholdG;
  final int requiredJolts;
  final Duration joltWindow;
  final Duration minJoltGap;
  final Duration cooldown;

  final List<DateTime> _jolts = [];
  DateTime? _lastShake;

  /// Memasukkan satu sampel akselerometer. True kalau sampel ini melengkapi sebuah goyangan.
  bool addSample(Vec3 acceleration, DateTime now) {
    if (acceleration.length / standardGravity < thresholdG) return false;

    final lastShake = _lastShake;
    if (lastShake != null && now.difference(lastShake) < cooldown) return false;

    _jolts.removeWhere((time) => now.difference(time) > joltWindow);
    if (_jolts.isNotEmpty && now.difference(_jolts.last) < minJoltGap) return false;

    _jolts.add(now);
    if (_jolts.length < requiredJolts) return false;

    _jolts.clear();
    _lastShake = now;
    return true;
  }
}
