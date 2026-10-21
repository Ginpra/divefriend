import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:divefriend/services/feedback_store.dart';
import 'package:divefriend/services/quiz_score_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('riwayat saran dan kesan tersimpan per pengguna, terbaru di atas', () async {
    final store = FeedbackStore();
    expect(await store.history(1), isEmpty);

    await store.add(1, impression: 'Seru', suggestion: 'Tambah praktik', now: DateTime(2026, 10, 21, 9));
    await store.add(1, impression: 'Mantap', suggestion: 'Tambah kuis', now: DateTime(2026, 10, 22, 9));

    final history = await store.history(1);
    expect(history.length, 2);
    expect(history.first.impression, 'Mantap');
    expect(history.last.suggestion, 'Tambah praktik');
    expect(await store.history(2), isEmpty);
  });

  test('satu catatan bisa dihapus tanpa menyentuh yang lain', () async {
    final store = FeedbackStore();
    await store.add(1, impression: 'A', suggestion: 'B', now: DateTime(2026, 10, 21, 9));
    await store.add(1, impression: 'C', suggestion: 'D', now: DateTime(2026, 10, 22, 9));

    final first = (await store.history(1)).last;
    await store.remove(1, first.id);

    final history = await store.history(1);
    expect(history.length, 1);
    expect(history.single.impression, 'C');
  });

  test('clear menghapus seluruh riwayat satu pengguna saja', () async {
    final store = FeedbackStore();
    await store.add(1, impression: 'A', suggestion: 'B');
    await store.add(2, impression: 'C', suggestion: 'D');

    await store.clear(1);

    expect(await store.history(1), isEmpty);
    expect(await store.history(2), isNotEmpty);
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
