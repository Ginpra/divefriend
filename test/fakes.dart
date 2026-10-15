import 'package:divefriend/data/models/app_user.dart';
import 'package:divefriend/data/repositories/user_repository.dart';
import 'package:divefriend/services/biometric_service.dart';

/// Penyimpanan pengguna di memori, dipakai tes agar tidak butuh SQLite asli.
class InMemoryUserRepository implements UserRepository {
  final List<AppUser> _users = [];

  @override
  Future<AppUser?> findByUsername(String username) async {
    for (final user in _users) {
      if (user.username == username) return user;
    }
    return null;
  }

  @override
  Future<AppUser?> findById(int id) async {
    for (final user in _users) {
      if (user.id == id) return user;
    }
    return null;
  }

  @override
  Future<AppUser> create({
    required String name,
    required String username,
    required String passwordHash,
    required String salt,
  }) async {
    final user = AppUser(
      id: _users.length + 1,
      name: name,
      username: username,
      passwordHash: passwordHash,
      salt: salt,
    );
    _users.add(user);
    return user;
  }

  @override
  Future<void> updatePhotoPath(int id, String? photoPath) async {
    final index = _users.indexWhere((user) => user.id == id);
    if (index != -1) _users[index] = _users[index].withPhoto(photoPath);
  }
}

/// Biometrik palsu: hasilnya bisa diatur dari tes.
class FakeBiometric extends BiometricService {
  FakeBiometric({this.available = true, this.succeeds = true});

  final bool available;
  final bool succeeds;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async => succeeds;
}
