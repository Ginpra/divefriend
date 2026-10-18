import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import 'package:divefriend/core/compass_math.dart';
import 'package:divefriend/core/shake_detector.dart';
import 'package:divefriend/core/vec3.dart';

/// Kontrak sensor gerak HP. Layar hanya bergantung pada kelas ini, jadi tes bisa memakai versi palsu.
abstract class SensorService {
  /// Aliran arah atas HP dalam derajat dari utara magnetik. Berisi error kalau HP tidak punya sensornya.
  Stream<double> headings();

  /// Aliran kejadian "HP digoyang".
  Stream<void> shakes();
}

/// Sensor asli lewat paket sensors_plus: magnetometer + akselerometer untuk kompas,
/// akselerometer untuk goyang. Sensor hanya menyala selama ada yang mendengarkan alirannya.
class DeviceSensorService implements SensorService {
  static const Duration _compassPeriod = Duration(milliseconds: 80);
  static const Duration _shakePeriod = Duration(milliseconds: 50);

  @override
  Stream<double> headings() {
    final controller = StreamController<double>();
    StreamSubscription<AccelerometerEvent>? accelerometerSubscription;
    StreamSubscription<MagnetometerEvent>? magnetometerSubscription;
    Vec3? gravity;
    Vec3? magnetic;

    controller.onListen = () {
      accelerometerSubscription = accelerometerEventStream(
        samplingPeriod: _compassPeriod,
      ).listen(
        (event) {
          gravity = smoothVec3(gravity, Vec3(event.x, event.y, event.z));
        },
        onError: controller.addError,
      );
      magnetometerSubscription = magnetometerEventStream(
        samplingPeriod: _compassPeriod,
      ).listen(
        (event) {
          final smoothedMagnetic = smoothVec3(magnetic, Vec3(event.x, event.y, event.z));
          magnetic = smoothedMagnetic;
          final currentGravity = gravity;
          if (currentGravity == null) return;
          final heading = headingDegrees(currentGravity, smoothedMagnetic);
          if (heading != null) controller.add(heading);
        },
        onError: controller.addError,
      );
    };
    controller.onCancel = () async {
      await accelerometerSubscription?.cancel();
      await magnetometerSubscription?.cancel();
      await controller.close();
    };
    return controller.stream;
  }

  @override
  Stream<void> shakes() {
    final detector = ShakeDetector();
    return accelerometerEventStream(samplingPeriod: _shakePeriod)
        .where((event) => detector.addSample(Vec3(event.x, event.y, event.z), DateTime.now()))
        .map<void>((_) {});
  }
}
