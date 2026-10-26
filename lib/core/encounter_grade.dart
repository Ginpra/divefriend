import 'dart:math';

/// Grade satu perjumpaan biota di game goyang. Ini hadiah keberuntungan di dalam game,
/// bukan penilaian kelangkaan atau status konservasi biota yang sebenarnya.
/// Urutan enum dari terendah ke tertinggi, jadi [index] bisa dipakai untuk membandingkan.
enum EncounterGrade {
  biasa('Biasa', 50),
  langka('Langka', 30),
  epik('Epik', 15),
  legendaris('Legendaris', 5);

  const EncounterGrade(this.label, this.weight);

  final String label;

  /// Peluang dalam persen. Jumlah semua bobot harus 100.
  final int weight;
}

/// Mengundi satu grade menurut bobot tiap grade.
EncounterGrade rollGrade([Random? random]) {
  final rng = random ?? Random();
  var roll = rng.nextInt(100);
  for (final grade in EncounterGrade.values) {
    if (roll < grade.weight) return grade;
    roll -= grade.weight;
  }
  return EncounterGrade.biasa;
}

/// Mengubah angka tersimpan jadi grade. Angka di luar jangkauan dianggap Biasa.
EncounterGrade gradeFromIndex(int index) {
  if (index < 0 || index >= EncounterGrade.values.length) return EncounterGrade.biasa;
  return EncounterGrade.values[index];
}
