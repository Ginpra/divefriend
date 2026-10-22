import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/quiz_builder.dart';
import 'package:divefriend/data/models/booking.dart';
import 'package:divefriend/services/account_deleter.dart';
import 'package:divefriend/services/auth_service.dart';
import 'package:divefriend/services/biota_store.dart';
import 'package:divefriend/services/feedback_store.dart';
import 'package:divefriend/services/quiz_score_store.dart';
import 'fakes.dart';

AuthService _newAuth() => AuthService(InMemoryUserRepository(), FakeBiometric());

Booking _booking(int userId) {
  return Booking(
    userId: userId,
    spotId: 'banda',
    spotName: 'Kepulauan Banda',
    diveDate: DateTime(2026, 11, 2),
    gatheringMinutes: 450,
    people: 2,
    priceIdrPerPerson: 3000000,
    createdAt: DateTime(2026, 10, 21, 9),
  );
}

Future<int> _register(AppServices services, String username) async {
  final user = await services.auth.register(name: username, username: username, password: 'password123');
  return user.id;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('hapus akun menghapus semua data milik akun itu dan tidak menyentuh akun lain', () async {
    final notifications = FakeNotificationService();
    final services = buildTestServices(auth: _newAuth(), notifications: notifications);
    final feedback = FeedbackStore();
    final scores = QuizScoreStore();
    final biota = BiotaStore();

    final budi = await _register(services, 'budi');
    final sari = await _register(services, 'sari');

    for (final userId in [budi, sari]) {
      await services.bookings.add(_booking(userId));
      await services.logbook.addEntry(
        userId: userId,
        diveDate: DateTime(2026, 10, 1),
        spotId: 'bunaken',
        spotName: 'Taman Nasional Bunaken',
        maxDepthM: 18,
        bottomTimeMin: 40,
        notes: 'Catatan $userId',
      );
      await feedback.add(userId, impression: 'Kesan', suggestion: 'Saran');
      await scores.saveIfBest(userId, 7);
      await biota.record(userId, const BiotaPick(name: 'Penyu', spotName: 'Bunaken'));
    }

    await services.auth.login('budi', 'password123');
    await AccountDeleter(services, feedback: feedback, scores: scores, biota: biota).deleteCurrentAccount();

    // Akun Budi hilang sepenuhnya.
    expect(services.auth.currentUser, isNull);
    expect(await services.bookings.forUser(budi), isEmpty);
    expect(await services.logbook.entries(budi), isEmpty);
    expect(await feedback.history(budi), isEmpty);
    expect(await scores.bestScore(budi), 0);
    expect(await biota.last(budi), isNull);
    expect(notifications.cancelled, isNotEmpty);
    await expectLater(services.auth.login('budi', 'password123'), throwsA(isA<AuthException>()));

    // Data Sari utuh dan akunnya masih bisa dipakai.
    expect(await services.bookings.forUser(sari), hasLength(1));
    expect(await services.logbook.entries(sari), hasLength(1));
    expect(await feedback.history(sari), hasLength(1));
    expect(await scores.bestScore(sari), 7);
    expect((await biota.last(sari))?.name, 'Penyu');
    final user = await services.auth.login('sari', 'password123');
    expect(user.id, sari);
  });

  test('tanpa akun yang login, hapus akun tidak melakukan apa-apa', () async {
    final services = buildTestServices(auth: _newAuth());
    await AccountDeleter(services).deleteCurrentAccount();
    expect(services.auth.currentUser, isNull);
  });

  test('biometrik milik akun yang dihapus ikut dibersihkan', () async {
    final services = buildTestServices(auth: _newAuth());
    await _register(services, 'budi');
    await services.auth.login('budi', 'password123');
    expect(await services.auth.enableBiometric(), isTrue);

    await services.auth.deleteAccount();

    expect(await services.auth.canLoginWithBiometric(), isFalse);
  });
}
