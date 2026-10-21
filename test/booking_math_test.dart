import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/core/booking_math.dart';
import 'package:divefriend/core/time_zones.dart';
import 'package:divefriend/data/models/booking.dart';

void main() {
  test('pengingat 1 jam sebelum jam kumpul di WIT dihitung dalam UTC', () {
    // 07.30 WIT (UTC+9) tanggal 2 November = 22.30 UTC tanggal 1 November, dikurangi 1 jam.
    final result = reminderTime(
      diveDate: DateTime(2026, 11, 2),
      gatheringMinutes: 7 * 60 + 30,
      zone: TimeZoneId.wit,
      option: ReminderOption.hourBefore,
    );
    expect(result, isNotNull);
    expect(result!.isAtSameMomentAs(DateTime.utc(2026, 11, 1, 21, 30)), isTrue);
  });

  test('pengingat 1 hari sebelumnya di WIB', () {
    final result = reminderTime(
      diveDate: DateTime(2026, 11, 2),
      gatheringMinutes: 8 * 60,
      zone: TimeZoneId.wib,
      option: ReminderOption.dayBefore,
    );
    // 08.00 WIB = 01.00 UTC, dikurangi satu hari.
    expect(result!.isAtSameMomentAs(DateTime.utc(2026, 11, 1, 1, 0)), isTrue);
  });

  test('tanpa pengingat menghasilkan null', () {
    final result = reminderTime(
      diveDate: DateTime(2026, 11, 2),
      gatheringMinutes: 450,
      zone: TimeZoneId.wita,
      option: ReminderOption.none,
    );
    expect(result, isNull);
  });

  test('jam kumpul di London memakai BST saat musim panas', () {
    final instant = gatheringInstantUtc(
      diveDate: DateTime(2026, 7, 1),
      gatheringMinutes: 9 * 60,
      zone: TimeZoneId.london,
    );
    expect(instant, DateTime.utc(2026, 7, 1, 8, 0));
  });

  test('total booking = harga per orang x jumlah peserta', () {
    final booking = Booking(
      id: 1,
      userId: 7,
      spotId: 'banda',
      spotName: 'Kepulauan Banda',
      diveDate: DateTime(2026, 11, 2),
      gatheringMinutes: 450,
      people: 3,
      priceIdrPerPerson: 3000000,
      createdAt: DateTime(2026, 10, 21, 9, 0),
    );
    expect(booking.totalIdr, 9000000);
    expect(booking.gatheringHour, 7);
    expect(booking.gatheringMinute, 30);
  });

  test('Booking bisa disimpan ke map lalu dibaca kembali', () {
    final booking = Booking(
      id: 5,
      userId: 7,
      spotId: 'banda',
      spotName: 'Kepulauan Banda',
      diveDate: DateTime(2026, 11, 2),
      gatheringMinutes: 450,
      people: 2,
      priceIdrPerPerson: 3000000,
      createdAt: DateTime(2026, 10, 21, 9, 0),
    );
    final copy = Booking.fromMap(booking.toMap());
    expect(copy.id, 5);
    expect(copy.diveDate, DateTime(2026, 11, 2));
    expect(copy.people, 2);
    expect(copy.priceIdrPerPerson, 3000000);
    expect(copy.createdAt, DateTime(2026, 10, 21, 9, 0));
  });

  group('konversi jam pengguna ke jam spot', () {
    const wib = Duration(hours: 7);

    test('10.00 WIB menjadi 12.00 WIT di Banda', () {
      final spotWall = userWallToSpotWall(
        userWall: DateTime.utc(2026, 11, 2, 10, 0),
        userOffset: wib,
        spotZone: TimeZoneId.wit,
      );
      expect(spotWall, DateTime.utc(2026, 11, 2, 12, 0));
      expect(dayShiftNote(DateTime.utc(2026, 11, 2, 10, 0), spotWall), isNull);
    });

    test('23.00 WIB menjadi 01.00 WIT di hari berikutnya', () {
      final userWall = DateTime.utc(2026, 11, 2, 23, 0);
      final spotWall = userWallToSpotWall(userWall: userWall, userOffset: wib, spotZone: TimeZoneId.wit);
      expect(spotWall, DateTime.utc(2026, 11, 3, 1, 0));
      expect(dayShiftNote(userWall, spotWall), 'hari berikutnya');
    });

    test('08.00 WITA menjadi 07.00 WIB di Karimunjawa', () {
      final spotWall = userWallToSpotWall(
        userWall: DateTime.utc(2026, 11, 2, 8, 0),
        userOffset: const Duration(hours: 8),
        spotZone: TimeZoneId.wib,
      );
      expect(spotWall, DateTime.utc(2026, 11, 2, 7, 0));
    });

    test('pengguna di London (GMT) 09.00 menjadi 16.00 WIB', () {
      final userWall = DateTime.utc(2026, 11, 2, 9, 0);
      final spotWall = userWallToSpotWall(userWall: userWall, userOffset: Duration.zero, spotZone: TimeZoneId.wib);
      expect(spotWall, DateTime.utc(2026, 11, 2, 16, 0));
    });

    test('hari bisa mundur kalau spot lebih barat dari pengguna', () {
      final userWall = DateTime.utc(2026, 11, 2, 1, 0);
      final spotWall = userWallToSpotWall(
        userWall: userWall,
        userOffset: const Duration(hours: 9),
        spotZone: TimeZoneId.wib,
      );
      expect(spotWall, DateTime.utc(2026, 11, 1, 23, 0));
      expect(dayShiftNote(userWall, spotWall), 'hari sebelumnya');
    });
  });

  test('label zona pengguna', () {
    expect(userZoneLabel(const Duration(hours: 7)), 'WIB');
    expect(userZoneLabel(const Duration(hours: 8)), 'WITA');
    expect(userZoneLabel(const Duration(hours: 9)), 'WIT');
    expect(userZoneLabel(const Duration(hours: 1)), 'UTC+1');
    expect(userZoneLabel(const Duration(hours: 5, minutes: 30)), 'UTC+5:30');
    expect(userZoneLabel(const Duration(hours: -5)), 'UTC-5');
  });
}
