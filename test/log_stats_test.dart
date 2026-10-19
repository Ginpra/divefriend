import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/core/log_stats.dart';
import 'package:divefriend/data/models/log_entry.dart';

LogEntry _entry(int seq, String spotId, int depth, int minutes) {
  return LogEntry(
    userId: 1,
    seq: seq,
    diveDate: '2026-10-1$seq',
    spotId: spotId,
    spotName: spotId,
    maxDepthM: depth,
    bottomTimeMin: minutes,
    notes: '',
    createdAt: '2026-10-18T03:00:00.000Z',
    prevHash: '',
    hash: '',
  );
}

void main() {
  test('logbook kosong menghasilkan nol semua', () {
    final stats = computeLogStats(const []);
    expect(stats.diveCount, 0);
    expect(stats.totalBottomMinutes, 0);
    expect(stats.deepestMeters, 0);
    expect(stats.distinctSpots, 0);
  });

  test('menghitung jumlah, total menit, terdalam, dan spot berbeda', () {
    final stats = computeLogStats([
      _entry(1, 'banda', 18, 45),
      _entry(2, 'komodo', 30, 40),
      _entry(3, 'banda', 12, 35),
    ]);
    expect(stats.diveCount, 3);
    expect(stats.totalBottomMinutes, 120);
    expect(stats.deepestMeters, 30);
    expect(stats.distinctSpots, 2);
  });

  test('formatDuration', () {
    expect(formatDuration(45), '45 menit');
    expect(formatDuration(60), '1 jam');
    expect(formatDuration(125), '2 jam 5 menit');
    expect(formatDuration(0), '0 menit');
  });
}
