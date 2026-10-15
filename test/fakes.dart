import 'package:divefriend/data/models/app_user.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/data/repositories/spot_repository.dart';
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

/// Spot di memori (urut nama, seperti SQLite), dipakai tes layar.
class InMemorySpotRepository implements SpotRepository {
  InMemorySpotRepository(List<Spot> spots)
      : _spots = [...spots]..sort((a, b) => a.name.compareTo(b.name));

  final List<Spot> _spots;

  @override
  Future<List<Spot>> getSpots({String query = '', SpotLevel? level}) async {
    final normalizedQuery = query.trim().toLowerCase();
    return _spots.where((spot) {
      final matchesLevel = level == null || spot.level == level;
      final matchesQuery = normalizedQuery.isEmpty ||
          spot.name.toLowerCase().contains(normalizedQuery) ||
          spot.region.toLowerCase().contains(normalizedQuery);
      return matchesLevel && matchesQuery;
    }).toList();
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
