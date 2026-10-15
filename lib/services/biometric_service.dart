import 'package:local_auth/local_auth.dart';

/// Pembungkus local_auth supaya kode lain tidak perlu tahu detail paketnya.
/// Semua kegagalan (tidak ada sensor, dibatalkan, dll.) dijadikan `false`.
class BiometricService {
  late final LocalAuthentication _auth = LocalAuthentication();

  /// True bila HP punya sensor DAN sudah ada sidik jari/wajah yang terdaftar.
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } on LocalAuthException {
      return false;
    }
  }
}
