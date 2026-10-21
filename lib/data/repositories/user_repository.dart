import 'package:divefriend/data/models/app_user.dart';

/// Kontrak penyimpanan pengguna. Aslinya SQLite; saat tes diganti versi memori.
abstract class UserRepository {
  Future<AppUser?> findByUsername(String username);
  Future<AppUser?> findById(int id);
  Future<AppUser> create({
    required String name,
    required String username,
    required String passwordHash,
    required String salt,
  });
  Future<void> updatePhotoPath(int id, String? photoPath);

  /// Menghapus akun beserta barisnya di tabel pengguna.
  Future<void> delete(int id);
}
