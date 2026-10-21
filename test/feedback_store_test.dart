import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:divefriend/services/feedback_store.dart';
import 'package:divefriend/services/quiz_score_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saran dan kesan tersimpan per pengguna', () async {
    final store = FeedbackStore();
    expect(await store.load(1), isNull);

    await store.save(1, const FeedbackEntry(impression: 'Seru', suggestion: 'Tambah praktik'));

    final loaded = await store.load(1);
    expect(loaded?.impression, 'Seru');
    expect(loaded?.suggestion, 'Tambah praktik');
    expect(await store.load(2), isNull);
  });

  test('menyimpan lagi menimpa isi lama', () async {
    final store = FeedbackStore();
    await store.save(1, const FeedbackEntry(impression: 'A', suggestion: 'B'));
    await store.save(1, const FeedbackEntry(impression: 'C', suggestion: 'D'));

    expect((await store.load(1))?.impression, 'C');
  });

  test('skor kuis hanya diganti kalau lebih tinggi', () async {
    final scores = QuizScoreStore();
    expect(await scores.bestScore(1), 0);

    expect(await scores.saveIfBest(1, 6), isTrue);
    expect(await scores.saveIfBest(1, 4), isFalse);
    expect(await scores.bestScore(1), 6);
    expect(await scores.bestScore(2), 0);
  });
}
