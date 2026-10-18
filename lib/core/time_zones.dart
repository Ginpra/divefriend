/// Konversi waktu WIB, WITA, WIT, dan London tanpa API.
/// Indonesia tidak memakai waktu musim panas. London memakainya (BST), dengan aturan:
/// mulai hari Minggu terakhir bulan Maret dan berakhir hari Minggu terakhir bulan Oktober,
/// keduanya pukul 01.00 UTC (sumber: gov.uk/when-do-the-clocks-change).
///
/// Semua [DateTime] di file ini dibuat dengan DateTime.utc. Untuk "jam dinding" (jam yang
/// terbaca di jam tangan) angkanya dipinjam dalam bentuk UTC supaya hitungan tidak ikut
/// zona waktu HP. Untuk satu-satunya jam yang bisa ambigu (jam yang diulang saat
/// London mundur ke GMT) dipakai pembacaan musim panas.
enum TimeZoneId {
  wib('WIB', 'Waktu Indonesia Barat'),
  wita('WITA', 'Waktu Indonesia Tengah'),
  wit('WIT', 'Waktu Indonesia Timur'),
  london('London', 'London, Inggris');

  const TimeZoneId(this.label, this.description);

  final String label;
  final String description;

  /// Selisih zona ini terhadap UTC pada saat [utc].
  Duration offsetAtUtc(DateTime utc) {
    return switch (this) {
      TimeZoneId.wib => const Duration(hours: 7),
      TimeZoneId.wita => const Duration(hours: 8),
      TimeZoneId.wit => const Duration(hours: 9),
      TimeZoneId.london =>
        isBritishSummerTime(utc) ? const Duration(hours: 1) : Duration.zero,
    };
  }
}

/// Hari Minggu terakhir pada [month] di [year], tengah malam UTC.
DateTime _lastSunday(int year, int month) {
  final lastDay = DateTime.utc(year, month + 1, 0);
  return lastDay.subtract(Duration(days: lastDay.weekday % DateTime.sunday));
}

/// True kalau London sedang memakai BST pada saat [utc].
bool isBritishSummerTime(DateTime utc) {
  final start = _lastSunday(utc.year, DateTime.march).add(const Duration(hours: 1));
  final end = _lastSunday(utc.year, DateTime.october).add(const Duration(hours: 1));
  return !utc.isBefore(start) && utc.isBefore(end);
}

/// Mengubah label di data spot ("WIB", "WITA", "WIT") jadi zona. Null kalau tidak dikenal.
TimeZoneId? zoneFromLabel(String? label) {
  for (final zone in TimeZoneId.values) {
    if (zone.label == label) return zone;
  }
  return null;
}

DateTime wallToUtc(TimeZoneId zone, DateTime wall) {
  if (zone == TimeZoneId.london) {
    final ifSummer = wall.subtract(const Duration(hours: 1));
    return isBritishSummerTime(ifSummer) ? ifSummer : wall;
  }
  return wall.subtract(zone.offsetAtUtc(wall));
}

DateTime utcToWall(TimeZoneId zone, DateTime utc) {
  return utc.add(zone.offsetAtUtc(utc));
}

/// Mengubah jam dinding di zona [from] menjadi jam dinding di zona [to].
DateTime convertWallTime(
  DateTime wall, {
  required TimeZoneId from,
  required TimeZoneId to,
}) {
  return utcToWall(to, wallToUtc(from, wall));
}

/// Singkatan zona pada saat [utc]. London berubah antara "BST" dan "GMT".
String zoneLabelAt(TimeZoneId zone, DateTime utc) {
  if (zone != TimeZoneId.london) return zone.label;
  return isBritishSummerTime(utc) ? 'BST' : 'GMT';
}

/// Jam dinding dalam bentuk "07.30".
String formatClock(DateTime wall) {
  final hour = wall.hour.toString().padLeft(2, '0');
  final minute = wall.minute.toString().padLeft(2, '0');
  return '$hour.$minute';
}

/// Keterangan kalau tanggal [to] berbeda dari [from], null kalau harinya sama.
String? dayShiftNote(DateTime from, DateTime to) {
  final fromDay = DateTime.utc(from.year, from.month, from.day);
  final toDay = DateTime.utc(to.year, to.month, to.day);
  final difference = toDay.difference(fromDay).inDays;
  if (difference < 0) return 'hari sebelumnya';
  if (difference > 0) return 'hari berikutnya';
  return null;
}
