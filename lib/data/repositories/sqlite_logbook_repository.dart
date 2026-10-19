import 'package:divefriend/data/local/app_database.dart';
import 'package:divefriend/data/models/log_entry.dart';
import 'package:divefriend/data/repositories/logbook_repository.dart';

class SqliteLogbookRepository implements LogbookRepository {
  SqliteLogbookRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<List<LogEntry>> entriesFor(int userId) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'logbook',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'seq ASC',
    );
    return rows.map(LogEntry.fromMap).toList();
  }

  @override
  Future<void> replaceAll(int userId, List<LogEntry> entries) async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      await txn.delete('logbook', where: 'user_id = ?', whereArgs: [userId]);
      for (final entry in entries) {
        await txn.insert('logbook', entry.toMap());
      }
    });
  }

  @override
  Future<void> rewriteNotesWithoutRehash(int userId, int seq, String notes) async {
    final db = await _appDatabase.database;
    await db.update(
      'logbook',
      {'notes': notes},
      where: 'user_id = ? AND seq = ?',
      whereArgs: [userId, seq],
    );
  }
}
