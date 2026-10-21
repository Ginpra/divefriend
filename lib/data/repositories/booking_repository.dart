import 'package:divefriend/data/models/booking.dart';

/// Kontrak penyimpanan pesanan. Layar hanya bergantung pada kelas ini, jadi tes memakai versi di memori.
abstract class BookingRepository {
  /// Menyimpan pesanan baru dan mengembalikan nomor urutnya.
  Future<int> add(Booking booking);

  /// Pesanan milik [userId], yang terbaru di atas.
  Future<List<Booking>> forUser(int userId);

  Future<void> delete({required int userId, required int id});
}
