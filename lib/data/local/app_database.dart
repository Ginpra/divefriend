import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Pintu tunggal ke database SQLite lokal.
/// Versi 1: tabel users. Versi 2: tabel spots + meta. Versi 3: kolom history di spots.
/// Tahap berikutnya menambah tabel di sini dan menaikkan nomor versi.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const int _version = 3;

  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'divefriend.db');
    return openDatabase(
      path,
      version: _version,
      onCreate: (db, version) async {
        await _createUsersTable(db);
        await _createSpotTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createSpotTables(db);
        } else if (oldVersion < 3) {
          await db.execute('ALTER TABLE spots ADD COLUMN history TEXT');
        }
      },
    );
  }

  static Future<void> _createUsersTable(Database db) {
    return db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        photo_path TEXT
      )
    ''');
  }

  static Future<void> _createSpotTables(Database db) async {
    await db.execute('''
      CREATE TABLE spots (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        region TEXT NOT NULL,
        level TEXT NOT NULL,
        level_basis TEXT NOT NULL,
        types TEXT NOT NULL,
        summary TEXT,
        history TEXT,
        depth_m REAL,
        best_season TEXT,
        biota TEXT NOT NULL,
        price_idr INTEGER,
        latitude REAL,
        longitude REAL,
        time_zone TEXT,
        sources TEXT NOT NULL,
        photo_url TEXT,
        photo_credit TEXT,
        photo_license TEXT,
        photo_source_url TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }
}
