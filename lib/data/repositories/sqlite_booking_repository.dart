import 'package:divefriend/data/local/app_database.dart';
import 'package:divefriend/data/models/booking.dart';
import 'package:divefriend/data/repositories/booking_repository.dart';

class SqliteBookingRepository implements BookingRepository {
  SqliteBookingRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<int> add(Booking booking) async {
    final db = await _appDatabase.database;
    final values = booking.toMap()..remove('id');
    return db.insert('bookings', values);
  }

  @override
  Future<List<Booking>> forUser(int userId) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'bookings',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return rows.map(Booking.fromMap).toList();
  }

  @override
  Future<void> delete({required int userId, required int id}) async {
    final db = await _appDatabase.database;
    await db.delete(
      'bookings',
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
    );
  }

  @override
  Future<void> deleteAllForUser(int userId) async {
    final db = await _appDatabase.database;
    await db.delete('bookings', where: 'user_id = ?', whereArgs: [userId]);
  }
}
