import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Pintu tunggal ke database SQLite lokal.
/// Tahap berikutnya (spots, logbook, dst.) cukup menambah tabel di sini
/// dan menaikkan nomor versi.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'divefriend.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            username TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            salt TEXT NOT NULL,
            photo_path TEXT
          )
        ''');
      },
    );
  }
}
