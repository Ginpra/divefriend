import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:divefriend/data/local/app_database.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/data/repositories/spot_repository.dart';
import 'package:divefriend/data/seed/spots_seed.dart';

/// Spot dibaca dari SQLite. Data awal diisi dari [spotsSeed] bila versinya berbeda.
class SqliteSpotRepository implements SpotRepository {
  SqliteSpotRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  static const String _versionKey = 'spots_seed_version';

  /// Panggil sekali saat aplikasi dibuka, sebelum daftar spot dibaca.
  Future<void> ensureSeeded() async {
    final db = await _appDatabase.database;
    final rows = await db.query('meta', where: 'key = ?', whereArgs: [_versionKey]);
    final storedVersion = rows.isEmpty ? null : rows.first['value'];
    if (storedVersion == '$spotsSeedVersion') return;

    await db.transaction((txn) async {
      await txn.delete('spots');
      for (final spot in spotsSeed) {
        await txn.insert('spots', _toRow(spot));
      }
      await txn.insert(
        'meta',
        {'key': _versionKey, 'value': '$spotsSeedVersion'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<List<Spot>> getSpots({String query = '', SpotLevel? level}) async {
    final db = await _appDatabase.database;
    final conditions = <String>[];
    final args = <Object?>[];

    final trimmedQuery = query.trim();
    if (trimmedQuery.isNotEmpty) {
      conditions.add('(name LIKE ? OR region LIKE ?)');
      args.addAll(['%$trimmedQuery%', '%$trimmedQuery%']);
    }
    if (level != null) {
      conditions.add('level = ?');
      args.add(level.name);
    }

    final rows = await db.query(
      'spots',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'name',
    );
    return rows.map(_fromRow).toList();
  }

  Map<String, Object?> _toRow(Spot spot) {
    return {
      'id': spot.id,
      'name': spot.name,
      'region': spot.region,
      'level': spot.level.name,
      'level_basis': spot.levelBasis,
      'types': spot.types.map((type) => type.name).join(','),
      'summary': spot.summary,
      'depth_m': spot.depthMeters,
      'best_season': spot.bestSeason,
      'biota': jsonEncode(spot.biota),
      'price_idr': spot.priceEstimateIdr,
      'latitude': spot.latitude,
      'longitude': spot.longitude,
      'time_zone': spot.timeZoneLabel,
      'sources': jsonEncode(spot.sources),
      'photo_url': spot.photo?.url,
      'photo_credit': spot.photo?.credit,
      'photo_license': spot.photo?.license,
      'photo_source_url': spot.photo?.sourceUrl,
    };
  }

  Spot _fromRow(Map<String, Object?> row) {
    final photoUrl = row['photo_url'] as String?;
    return Spot(
      id: row['id'] as String,
      name: row['name'] as String,
      region: row['region'] as String,
      level: SpotLevel.values.byName(row['level'] as String),
      levelBasis: row['level_basis'] as String,
      types: (row['types'] as String)
          .split(',')
          .map((name) => SpotType.values.byName(name))
          .toList(),
      summary: row['summary'] as String?,
      depthMeters: row['depth_m'] as double?,
      bestSeason: row['best_season'] as String?,
      biota: (jsonDecode(row['biota'] as String) as List<dynamic>).cast<String>(),
      priceEstimateIdr: row['price_idr'] as int?,
      latitude: row['latitude'] as double?,
      longitude: row['longitude'] as double?,
      timeZoneLabel: row['time_zone'] as String?,
      sources: (jsonDecode(row['sources'] as String) as List<dynamic>).cast<String>(),
      photo: photoUrl == null
          ? null
          : SpotPhoto(
              url: photoUrl,
              credit: row['photo_credit'] as String,
              license: row['photo_license'] as String,
              sourceUrl: row['photo_source_url'] as String,
            ),
    );
  }
}
