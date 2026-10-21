import 'package:divefriend/core/time_zones.dart';

/// Batas jumlah peserta dalam satu pesanan simulasi.
const int maxPeoplePerBooking = 10;

/// Kapan pengingat dibunyikan, dihitung mundur dari jam kumpul.
enum ReminderOption {
  none('Tanpa pengingat', Duration.zero),
  dayBefore('1 hari sebelumnya', Duration(days: 1)),
  hourBefore('1 jam sebelumnya', Duration(hours: 1)),
  fiveMinutesBefore('5 menit sebelumnya', Duration(minutes: 5));

  const ReminderOption(this.label, this.before);

  final String label;
  final Duration before;
}

/// Saat jam kumpul sebagai satu titik waktu yang sama di seluruh dunia (UTC).
/// [diveDate] dan [gatheringMinutes] adalah jam dinding di zona waktu spot.
DateTime gatheringInstantUtc({
  required DateTime diveDate,
  required int gatheringMinutes,
  required TimeZoneId zone,
}) {
  final wall = DateTime.utc(
    diveDate.year,
    diveDate.month,
    diveDate.day,
    gatheringMinutes ~/ 60,
    gatheringMinutes % 60,
  );
  return wallToUtc(zone, wall);
}

/// Waktu pengingat menurut jam HP, atau null kalau pengguna memilih tanpa pengingat.
/// Hasilnya bisa sudah lewat, pemanggil yang memeriksa.
DateTime? reminderTime({
  required DateTime diveDate,
  required int gatheringMinutes,
  required TimeZoneId zone,
  required ReminderOption option,
}) {
  if (option == ReminderOption.none) return null;
  final gathering = gatheringInstantUtc(
    diveDate: diveDate,
    gatheringMinutes: gatheringMinutes,
    zone: zone,
  );
  return gathering.subtract(option.before).toLocal();
}
