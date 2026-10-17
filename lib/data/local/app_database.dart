import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Pintu tunggal ke database SQLite lokal.
/// Versi 1: tabel users. Versi 2: tabel spots + meta. Versi 4: struktur tabel spots dirapikan.
/// Tabel spots hanyalah salinan dari data seed, jadi saat strukturnya berubah
/// tabelnya dibuat ulang dan datanya dimuat lagi otomatis.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const int _version = 4;

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
        } else if (oldVersion < 4) {
          await db.execute('DROP TABLE IF EXISTS spots');
          await db.execute('DROP TABLE IF EXISTS meta');
          await _createSpotTables(db);
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
        tagline TEXT NOT NULL,
        summary TEXT NOT NULL,
        depth_text TEXT,
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
