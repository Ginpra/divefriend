import 'package:shared_preferences/shared_preferences.dart';

import 'package:divefriend/data/models/app_user.dart';
import 'package:divefriend/data/repositories/user_repository.dart';
import 'package:divefriend/services/biometric_service.dart';
import 'package:divefriend/services/password_hasher.dart';

/// Error yang pesannya aman ditampilkan langsung ke pengguna.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Register, login, session, dan login biometrik.
/// Session = id pengguna yang tersimpan lokal; selama ada, app langsung masuk Beranda.
class AuthService {
  AuthService(this._users, this._biometric);

  final UserRepository _users;
  final BiometricService _biometric;

  static const String _sessionKey = 'session_user_id';
  static const String _biometricKey = 'biometric_user_id';

  /// Pengguna yang sedang login (null = belum login).
  AppUser? currentUser;

  String _cleanUsername(String username) => username.trim().toLowerCase();

  Future<AppUser> register({
    required String name,
    required String username,
    required String password,
  }) async {
    final cleanUsername = _cleanUsername(username);
    if (await _users.findByUsername(cleanUsername) != null) {
      throw const AuthException('Username sudah dipakai');
    }
    final salt = PasswordHasher.generateSalt();
    return _users.create(
      name: name.trim(),
      username: cleanUsername,
      passwordHash: PasswordHasher.hash(password, salt),
      salt: salt,
    );
  }

  Future<AppUser> login(String username, String password) async {
    final user = await _users.findByUsername(_cleanUsername(username));
    final passwordMatches =
        user != null && PasswordHasher.hash(password, user.salt) == user.passwordHash;
    if (!passwordMatches) {
      // Pesan sengaja sama untuk "username tidak ada" dan "password salah".
      throw const AuthException('Username atau password salah');
    }
    await _startSession(user);
    return user;
  }

  Future<void> _startSession(AppUser user) async {
    currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionKey, user.id);
  }

  /// Dipanggil saat app dibuka: kalau masih ada session, pengguna langsung masuk.
  Future<AppUser?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_sessionKey);
    currentUser = id == null ? null : await _users.findById(id);
    return currentUser;
  }

  Future<void> logout() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<void> setPhoto(String? photoPath) async {
    final user = currentUser;
    if (user == null) return;
    await _users.updatePhotoPath(user.id, photoPath);
    currentUser = user.withPhoto(photoPath);
  }

  // ---- Login biometrik ----
  // Biometrik hanya jalan pintas masuk untuk akun yang sudah mengaktifkannya
  // (lewat Profil). Pertama kali tetap harus login dengan password.

  Future<bool> isBiometricAvailable() => _biometric.isAvailable();

  Future<bool> canLoginWithBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_biometricKey) && await _biometric.isAvailable();
  }

  Future<bool> isBiometricEnabled() async {
    final user = currentUser;
    if (user == null) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_biometricKey) == user.id;
  }

  Future<bool> enableBiometric() async {
    final user = currentUser;
    if (user == null) return false;
    final verified = await _biometric.isAvailable() &&
        await _biometric.authenticate('Aktifkan login biometrik');
    if (!verified) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_biometricKey, user.id);
    return true;
  }

  Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_biometricKey);
  }

  Future<AppUser?> loginWithBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_biometricKey);
    if (id == null) return null;
    if (!await _biometric.authenticate('Masuk ke DiveFriend')) return null;
    final user = await _users.findById(id);
    if (user != null) await _startSession(user);
    return user;
  }
}
