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
}
