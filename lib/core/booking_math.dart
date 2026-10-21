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

/// Label zona waktu pengguna dari selisihnya terhadap UTC. Zona Indonesia diberi nama,
/// zona lain ditulis "UTC+X".
String userZoneLabel(Duration offset) {
  if (offset == const Duration(hours: 7)) return 'WIB';
  if (offset == const Duration(hours: 8)) return 'WITA';
  if (offset == const Duration(hours: 9)) return 'WIT';
  final sign = offset.isNegative ? '-' : '+';
  final absolute = offset.abs();
  final hours = absolute.inHours;
  final minutes = absolute.inMinutes % 60;
  final minuteText = minutes == 0 ? '' : ':${minutes.toString().padLeft(2, '0')}';
  return 'UTC$sign$hours$minuteText';
}

/// Mengubah jam dinding pengguna menjadi jam dinding di zona spot.
/// [userWall] adalah jam yang dibaca pengguna di jam tangannya, dibuat dengan DateTime.utc supaya
/// tidak ikut zona HP. [userOffset] adalah selisih zona pengguna terhadap UTC saat itu.
/// Hasilnya juga jam dinding berbentuk DateTime.utc, tanggalnya bisa bergeser kalau melewati tengah malam.
DateTime userWallToSpotWall({
  required DateTime userWall,
  required Duration userOffset,
  required TimeZoneId spotZone,
}) {
  final instantUtc = userWall.subtract(userOffset);
  return utcToWall(spotZone, instantUtc);
}
