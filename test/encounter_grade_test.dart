import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/core/encounter_grade.dart';

void main() {
  test('jumlah bobot semua grade tepat 100 persen', () {
    final total = EncounterGrade.values.fold<int>(0, (sum, grade) => sum + grade.weight);
    expect(total, 100);
  });

  test('grade makin tinggi, peluangnya makin kecil', () {
    for (var i = 1; i < EncounterGrade.values.length; i++) {
      expect(EncounterGrade.values[i].weight, lessThan(EncounterGrade.values[i - 1].weight));
    }
  });

  test('rollGrade mengikuti bobot: 20.000 undian dengan benih tetap', () {
    final rng = Random(7);
    final counts = <EncounterGrade, int>{for (final grade in EncounterGrade.values) grade: 0};
    for (var i = 0; i < 20000; i++) {
      final grade = rollGrade(rng);
      counts[grade] = counts[grade]! + 1;
    }
    for (final grade in EncounterGrade.values) {
      final share = counts[grade]! / 20000 * 100;
      // Toleransi 1,5 poin persen dari bobot yang ditetapkan.
      expect(share, closeTo(grade.weight.toDouble(), 1.5), reason: grade.label);
    }
  });

  test('gradeFromIndex memulihkan grade dan menganggap angka aneh sebagai Biasa', () {
    expect(gradeFromIndex(EncounterGrade.legendaris.index), EncounterGrade.legendaris);
    expect(gradeFromIndex(-1), EncounterGrade.biasa);
    expect(gradeFromIndex(99), EncounterGrade.biasa);
  });
}
