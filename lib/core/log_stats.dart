import 'package:divefriend/data/models/log_entry.dart';

/// Ringkasan angka dari seluruh catatan di logbook.
class LogStats {
  const LogStats({
    required this.diveCount,
    required this.totalBottomMinutes,
    required this.deepestMeters,
    required this.distinctSpots,
  });

  final int diveCount;
  final int totalBottomMinutes;

  /// Kedalaman maksimum terbesar, 0 kalau logbook kosong.
  final int deepestMeters;
  final int distinctSpots;
}

LogStats computeLogStats(List<LogEntry> entries) {
  var totalMinutes = 0;
  var deepest = 0;
  for (final entry in entries) {
    totalMinutes += entry.bottomTimeMin;
    if (entry.maxDepthM > deepest) deepest = entry.maxDepthM;
  }
  return LogStats(
    diveCount: entries.length,
    totalBottomMinutes: totalMinutes,
    deepestMeters: deepest,
    distinctSpots: entries.map((entry) => entry.spotId).toSet().length,
  );
}

/// Lama dalam menit dibaca manusia: "45 menit", "2 jam", "2 jam 5 menit".
String formatDuration(int minutes) {
  if (minutes < 60) return '$minutes menit';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours jam' : '$hours jam $rest menit';
}
