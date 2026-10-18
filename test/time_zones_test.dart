import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/core/time_zones.dart';

/// Tanggal peralihan London dicocokkan dengan tabel resmi gov.uk/when-do-the-clocks-change:
/// 2026 maju 29 Maret dan mundur 25 Oktober, 2027 maju 28 Maret dan mundur 31 Oktober,
/// 2028 maju 26 Maret dan mundur 29 Oktober.
void main() {
  group('isBritishSummerTime', () {
    test('batas tepat pukul 01.00 UTC pada tahun 2026', () {
      expect(isBritishSummerTime(DateTime.utc(2026, 3, 29, 0, 59)), isFalse);
      expect(isBritishSummerTime(DateTime.utc(2026, 3, 29, 1, 0)), isTrue);
      expect(isBritishSummerTime(DateTime.utc(2026, 10, 25, 0, 59)), isTrue);
      expect(isBritishSummerTime(DateTime.utc(2026, 10, 25, 1, 0)), isFalse);
    });

    test('tahun 2027 dan 2028 mengikuti tabel gov.uk', () {
      expect(isBritishSummerTime(DateTime.utc(2027, 3, 27, 23)), isFalse);
      expect(isBritishSummerTime(DateTime.utc(2027, 3, 28, 1)), isTrue);
      expect(isBritishSummerTime(DateTime.utc(2027, 10, 30, 23)), isTrue);
      expect(isBritishSummerTime(DateTime.utc(2027, 10, 31, 1)), isFalse);
      expect(isBritishSummerTime(DateTime.utc(2028, 3, 25, 23)), isFalse);
      expect(isBritishSummerTime(DateTime.utc(2028, 3, 26, 1)), isTrue);
      expect(isBritishSummerTime(DateTime.utc(2028, 10, 28, 23)), isTrue);
      expect(isBritishSummerTime(DateTime.utc(2028, 10, 29, 1)), isFalse);
    });

    test('tengah musim panas dan tengah musim dingin', () {
      expect(isBritishSummerTime(DateTime.utc(2026, 7, 1, 12)), isTrue);
      expect(isBritishSummerTime(DateTime.utc(2026, 12, 1, 12)), isFalse);
      expect(isBritishSummerTime(DateTime.utc(2026, 1, 15, 12)), isFalse);
    });
  });

  group('konversi jam dinding', () {
    test('WIB ke London saat BST (24 Oktober 2026)', () {
      final london = convertWallTime(
        DateTime.utc(2026, 10, 24, 12),
        from: TimeZoneId.wib,
        to: TimeZoneId.london,
      );
      expect(london, DateTime.utc(2026, 10, 24, 6));
    });

    test('WIB ke London saat GMT (25 Oktober 2026)', () {
      final london = convertWallTime(
        DateTime.utc(2026, 10, 25, 12),
        from: TimeZoneId.wib,
        to: TimeZoneId.london,
      );
      expect(london, DateTime.utc(2026, 10, 25, 5));
    });

    test('WITA ke London bisa mundur ke hari sebelumnya', () {
      final wita = DateTime.utc(2026, 10, 26, 7, 30);
      final london = convertWallTime(wita, from: TimeZoneId.wita, to: TimeZoneId.london);
      expect(london, DateTime.utc(2026, 10, 25, 23, 30));
      expect(dayShiftNote(wita, london), 'hari sebelumnya');
    });

    test('WITA ke London saat BST masih di hari yang sama', () {
      final wita = DateTime.utc(2026, 10, 18, 7, 30);
      final london = convertWallTime(wita, from: TimeZoneId.wita, to: TimeZoneId.london);
      expect(london, DateTime.utc(2026, 10, 18, 0, 30));
      expect(dayShiftNote(wita, london), isNull);
    });

    test('London ke WIB dan WIT', () {
      final summer = DateTime.utc(2026, 7, 1, 9);
      expect(
        convertWallTime(summer, from: TimeZoneId.london, to: TimeZoneId.wib),
        DateTime.utc(2026, 7, 1, 15),
      );
      final winter = DateTime.utc(2026, 12, 1, 9);
      expect(
        convertWallTime(winter, from: TimeZoneId.london, to: TimeZoneId.wit),
        DateTime.utc(2026, 12, 1, 18),
      );
    });

    test('WIT ke WIB melewati tengah malam', () {
      final wit = DateTime.utc(2026, 12, 1, 2);
      final wib = convertWallTime(wit, from: TimeZoneId.wit, to: TimeZoneId.wib);
      expect(wib, DateTime.utc(2026, 12, 1, 0));
    });

    test('jam London yang diulang saat mundur dibaca sebagai BST', () {
      expect(
        wallToUtc(TimeZoneId.london, DateTime.utc(2026, 10, 25, 1, 30)),
        DateTime.utc(2026, 10, 25, 0, 30),
      );
      expect(
        wallToUtc(TimeZoneId.london, DateTime.utc(2026, 10, 25, 2, 30)),
        DateTime.utc(2026, 10, 25, 2, 30),
      );
    });

    test('bolak-balik antara zona Indonesia dan London kembali ke jam semula', () {
      for (final zone in [TimeZoneId.wib, TimeZoneId.wita, TimeZoneId.wit]) {
        final start = DateTime.utc(2026, 8, 10, 9, 15);
        final london = convertWallTime(start, from: zone, to: TimeZoneId.london);
        expect(convertWallTime(london, from: TimeZoneId.london, to: zone), start);
      }
    });
  });

  group('pembantu tampilan', () {
    test('zoneFromLabel mengenali label di data spot', () {
      expect(zoneFromLabel('WIB'), TimeZoneId.wib);
      expect(zoneFromLabel('WITA'), TimeZoneId.wita);
      expect(zoneFromLabel('WIT'), TimeZoneId.wit);
      expect(zoneFromLabel(null), isNull);
      expect(zoneFromLabel('XYZ'), isNull);
    });

    test('zoneLabelAt membedakan BST dan GMT', () {
      expect(zoneLabelAt(TimeZoneId.london, DateTime.utc(2026, 7, 1)), 'BST');
      expect(zoneLabelAt(TimeZoneId.london, DateTime.utc(2026, 12, 1)), 'GMT');
      expect(zoneLabelAt(TimeZoneId.wit, DateTime.utc(2026, 7, 1)), 'WIT');
    });

    test('formatClock memakai dua angka dan titik', () {
      expect(formatClock(DateTime.utc(2026, 1, 1, 7, 5)), '07.05');
      expect(formatClock(DateTime.utc(2026, 1, 1, 23, 30)), '23.30');
    });

    test('dayShiftNote untuk hari berikutnya', () {
      expect(
        dayShiftNote(DateTime.utc(2026, 5, 1, 22), DateTime.utc(2026, 5, 2, 5)),
        'hari berikutnya',
      );
    });
  });
}
