import 'dart:io';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/services/biota_store.dart';
import 'package:divefriend/services/feedback_store.dart';
import 'package:divefriend/services/preference_store.dart';
import 'package:divefriend/services/quiz_score_store.dart';

/// Menghapus akun yang sedang login beserta semua data miliknya, supaya tidak ada data yang tertinggal
/// dan tidak ada hubungannya dengan akun lain: pesanan beserta pengingatnya, logbook, saran dan kesan,
/// skor kuis, koleksi biota, foto profil, lalu akunnya sendiri.
class AccountDeleter {
  AccountDeleter(
    this._services, {
    FeedbackStore? feedback,
    QuizScoreStore? scores,
    BiotaStore? biota,
    PreferenceStore? preferences,
  })  : _preferences = preferences ?? PreferenceStore(),
        _feedback = feedback ?? FeedbackStore(),
        _scores = scores ?? QuizScoreStore(),
        _biota = biota ?? BiotaStore();

  final AppServices _services;
  final FeedbackStore _feedback;
  final QuizScoreStore _scores;
  final BiotaStore _biota;
  final PreferenceStore _preferences;

  Future<void> deleteCurrentAccount() async {
    final user = _services.auth.currentUser;
    if (user == null) return;
    final userId = user.id;

    for (final booking in await _services.bookings.forUser(userId)) {
      final bookingId = booking.id;
      if (bookingId == null) continue;
      try {
        await _services.notifications.cancelReminder(bookingId);
      } catch (_) {
        // Pengingat yang gagal dibatalkan tidak boleh menghentikan penghapusan akun.
      }
    }
    await _services.bookings.deleteAllForUser(userId);
    await _services.logbook.deleteAllFor(userId);
    await _feedback.clear(userId);
    await _scores.clear(userId);
    await _biota.clear(userId);
    await _preferences.clear(userId);

    final photoPath = user.photoPath;
    if (photoPath != null) {
      final file = File(photoPath);
      if (await file.exists()) await file.delete();
    }

    // Terakhir, supaya kalau ada langkah di atas gagal, akunnya masih ada dan penghapusan bisa diulang.
    await _services.auth.deleteAccount();
  }
}
