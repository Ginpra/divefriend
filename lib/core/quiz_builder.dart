import 'dart:math';

import 'package:divefriend/core/encounter_grade.dart';
import 'package:divefriend/data/models/spot.dart';

/// Satu soal kuis pilihan ganda.
class QuizQuestion {
  const QuizQuestion({
    required this.spotName,
    required this.options,
    required this.correctIndex,
  });

  final String spotName;
  final List<String> options;
  final int correctIndex;

  String get prompt => 'Biota mana yang tercatat di $spotName?';
  String get correctAnswer => options[correctIndex];
}

/// Satu biota beserta spot asalnya, dipakai fitur goyang biota hari ini.
class BiotaPick {
  const BiotaPick({
    required this.name,
    required this.spotName,
    this.grade = EncounterGrade.biasa,
  });

  final String name;
  final String spotName;

  /// Grade undian ini, ditentukan keberuntungan (lihat core/encounter_grade.dart).
  final EncounterGrade grade;
}

/// Isian daftar biota yang bukan hewan atau tumbuhan tunggal, tidak cocok jadi jawaban kuis.
const Set<String> _skippedFirstWords = {'bangkai', 'padang'};

/// Membuang keterangan dalam kurung, contoh "Kima raksasa (7 dari 8 spesies dunia)" jadi "Kima raksasa".
String cleanBiotaName(String raw) {
  final bracket = raw.indexOf(' (');
  final name = bracket == -1 ? raw : raw.substring(0, bracket);
  return name.trim();
}

/// Kata pertama huruf kecil, dipakai untuk mencegah pilihan yang mirip ("Penyu" dan "Penyu hijau").
String _key(String cleanName) => cleanName.split(' ').first.toLowerCase();

List<String> _usableBiota(Spot spot) {
  return [
    for (final raw in spot.biota)
      if (!_skippedFirstWords.contains(_key(cleanBiotaName(raw)))) cleanBiotaName(raw),
  ];
}

/// Menyusun kuis: satu soal per spot (diacak), tiap soal punya satu jawaban benar dari daftar biota
/// spot itu dan tiga pengecoh dari spot lain. Pengecoh tidak boleh mirip dengan biota yang tercatat
/// di spot tersebut, supaya jawabannya tidak ambigu. Spot yang tidak punya cukup pengecoh dilewati.
List<QuizQuestion> buildQuiz(List<Spot> spots, {int count = 10, Random? random}) {
  final rng = random ?? Random();
  final shuffledSpots = [...spots]..shuffle(rng);
  final questions = <QuizQuestion>[];

  for (final spot in shuffledSpots) {
    if (questions.length >= count) break;
    final own = _usableBiota(spot);
    if (own.isEmpty) continue;

    final ownKeys = own.map(_key).toSet();
    final decoys = <String>[];
    final usedKeys = <String>{...ownKeys};
    final pool = <String>[
      for (final other in spots)
        if (other.id != spot.id) ..._usableBiota(other),
    ]..shuffle(rng);
    for (final candidate in pool) {
      if (decoys.length == 3) break;
      if (usedKeys.add(_key(candidate))) decoys.add(candidate);
    }
    if (decoys.length < 3) continue;

    final correct = own[rng.nextInt(own.length)];
    final options = [correct, ...decoys]..shuffle(rng);
    questions.add(
      QuizQuestion(
        spotName: spot.name,
        options: options,
        correctIndex: options.indexOf(correct),
      ),
    );
  }
  return questions;
}

/// Jumlah biota berbeda (nama + spot) yang bisa diundi, dipakai untuk "ditemukan X dari Y".
int countBiota(List<Spot> spots) {
  return {
    for (final spot in spots)
      for (final name in _usableBiota(spot)) biotaKey(name, spot.name),
  }.length;
}

/// Kunci unik satu biota di satu spot, dipakai untuk koleksi.
String biotaKey(String name, String spotName) => '$name|$spotName';

/// Memilih satu biota acak dari seluruh spot. Null kalau tidak ada biota sama sekali.
BiotaPick? pickRandomBiota(List<Spot> spots, {Random? random}) {
  final rng = random ?? Random();
  final all = <BiotaPick>[
    for (final spot in spots)
      for (final name in _usableBiota(spot)) BiotaPick(name: name, spotName: spot.name),
  ];
  if (all.isEmpty) return null;
  final chosen = all[rng.nextInt(all.length)];
  return BiotaPick(name: chosen.name, spotName: chosen.spotName, grade: rollGrade(rng));
}
