/// Satu pengguna aplikasi. Password TIDAK pernah disimpan polos:
/// yang tersimpan hanya hasil hash (passwordHash) dan salt acaknya.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.passwordHash,
    required this.salt,
    this.photoPath,
  });

  final int id;
  final String name;
  final String username;
  final String passwordHash;
  final String salt;

  /// Lokasi file foto profil di penyimpanan app. Null = belum punya foto.
  final String? photoPath;

  AppUser withPhoto(String? newPhotoPath) {
    return AppUser(
      id: id,
      name: name,
      username: username,
      passwordHash: passwordHash,
      salt: salt,
      photoPath: newPhotoPath,
    );
  }
}
