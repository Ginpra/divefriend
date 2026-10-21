import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/core/quiz_builder.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/data/seed/spots_seed.dart';

Spot _spot(String id, List<String> biota) {
  return Spot(
    id: id,
    name: 'Spot $id',
    region: 'Wilayah',
    level: SpotLevel.pemula,
    levelBasis: 'Contoh',
    types: const [SpotType.scuba],
    tagline: 'Contoh',
    summary: 'Contoh',
    sources: const ['Contoh'],
    biota: biota,
  );
}

String _key(String name) => name.split(' ').first.toLowerCase();

void main() {
  test('cleanBiotaName membuang keterangan dalam kurung', () {
    expect(cleanBiotaName('Kima raksasa (7 dari 8 spesies dunia)'), 'Kima raksasa');
    expect(cleanBiotaName('Penyu'), 'Penyu');
  });

  test('kuis dari data asli: empat pilihan unik, jawaban benar ada di daftar biota spot', () {
    final questions = buildQuiz(spotsSeed, random: Random(1));

    expect(questions.length, 10);
    for (final question in questions) {
      expect(question.options.length, 4);
      expect(question.options.toSet().length, 4);
      expect(question.correctIndex, inInclusiveRange(0, 3));

      final spot = spotsSeed.firstWhere((item) => item.name == question.spotName);
      final ownNames = spot.biota.map(cleanBiotaName).toSet();
      expect(ownNames.contains(question.correctAnswer), isTrue);

      // Pengecoh tidak boleh mirip dengan biota spot ini (kata pertama sama).
      final ownKeys = ownNames.map(_key).toSet();
      for (var i = 0; i < question.options.length; i++) {
        if (i == question.correctIndex) continue;
        expect(ownKeys.contains(_key(question.options[i])), isFalse);
      }
    }
  });

  test('jumlah soal mengikuti permintaan', () {
    expect(buildQuiz(spotsSeed, count: 5, random: Random(2)).length, 5);
  });

  test('satu spot saja tidak punya pengecoh sehingga kuis kosong', () {
    expect(buildQuiz([_spot('a', ['Penyu', 'Hiu'])], random: Random(3)), isEmpty);
  });

  test('pengecoh yang mirip jawaban dilewati', () {
    final spots = [
      _spot('a', ['Penyu hijau']),
      _spot('b', ['Penyu sisik', 'Hiu paus', 'Pari manta', 'Dugong']),
    ];
    final questions = buildQuiz(spots, random: Random(4));
    for (final question in questions) {
      if (question.spotName == 'Spot a') {
        expect(question.options.where((option) => option.startsWith('Penyu')).length, 1);
      }
    }
  });

  test('pickRandomBiota mengembalikan null kalau tidak ada biota', () {
    expect(pickRandomBiota([_spot('a', const [])]), isNull);
    final pick = pickRandomBiota([_spot('a', ['Hiu paus'])], random: Random(1));
    expect(pick?.name, 'Hiu paus');
    expect(pick?.spotName, 'Spot a');
  });
}
