/// Satu pesanan trip selam. Ini simulasi: tidak ada pembayaran dan tidak dikirim ke operator mana pun.
class Booking {
  const Booking({
    this.id,
    required this.userId,
    required this.spotId,
    required this.spotName,
    required this.diveDate,
    required this.gatheringMinutes,
    required this.people,
    required this.priceIdrPerPerson,
    required this.createdAt,
  });

  /// Kosong sebelum disimpan, diisi nomor urut oleh database.
  final int? id;
  final int userId;
  final String spotId;
  final String spotName;

  /// Tanggal selam. Jamnya tidak dipakai, jam kumpul disimpan terpisah.
  final DateTime diveDate;

  /// Jam kumpul waktu setempat spot, dalam menit sejak tengah malam (07.30 = 450).
  final int gatheringMinutes;
  final int people;

  /// Harga paket simulasi per orang saat pesanan dibuat, jadi tidak berubah walau data spot berubah.
  final int priceIdrPerPerson;
  final DateTime createdAt;

  int get totalIdr => priceIdrPerPerson * people;
  int get gatheringHour => gatheringMinutes ~/ 60;
  int get gatheringMinute => gatheringMinutes % 60;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'spot_id': spotId,
      'spot_name': spotName,
      'dive_date': diveDate.toIso8601String().substring(0, 10),
      'gathering_minutes': gatheringMinutes,
      'people': people,
      'price_idr': priceIdrPerPerson,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Booking.fromMap(Map<String, Object?> map) {
    return Booking(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      spotId: map['spot_id'] as String,
      spotName: map['spot_name'] as String,
      diveDate: DateTime.parse(map['dive_date'] as String),
      gatheringMinutes: map['gathering_minutes'] as int,
      people: map['people'] as int,
      priceIdrPerPerson: map['price_idr'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
