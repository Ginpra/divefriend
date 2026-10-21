import 'package:divefriend/data/local/app_database.dart';
import 'package:divefriend/data/models/app_user.dart';
import 'package:divefriend/data/repositories/user_repository.dart';

class SqliteUserRepository implements UserRepository {
  SqliteUserRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  AppUser _fromRow(Map<String, Object?> row) {
    return AppUser(
      id: row['id'] as int,
      name: row['name'] as String,
      username: row['username'] as String,
      passwordHash: row['password_hash'] as String,
      salt: row['salt'] as String,
      photoPath: row['photo_path'] as String?,
    );
  }

  Future<AppUser?> _findOne(String where, List<Object?> args) async {
    final db = await _appDatabase.database;
    final rows = await db.query('users', where: where, whereArgs: args, limit: 1);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<AppUser?> findByUsername(String username) {
    return _findOne('username = ?', [username]);
  }

  @override
  Future<AppUser?> findById(int id) => _findOne('id = ?', [id]);

  @override
  Future<AppUser> create({
    required String name,
    required String username,
    required String passwordHash,
    required String salt,
  }) async {
    final db = await _appDatabase.database;
    final id = await db.insert('users', {
      'name': name,
      'username': username,
      'password_hash': passwordHash,
      'salt': salt,
    });
    return AppUser(
      id: id,
      name: name,
      username: username,
      passwordHash: passwordHash,
      salt: salt,
    );
  }

  @override
  Future<void> updatePhotoPath(int id, String? photoPath) async {
    final db = await _appDatabase.database;
    await db.update(
      'users',
      {'photo_path': photoPath},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> delete(int id) async {
    final db = await _appDatabase.database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}
