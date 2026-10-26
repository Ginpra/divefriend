import 'dart:math' as math;

import 'package:divefriend/data/models/spot.dart';

/// Satu pertanyaan pilihan tunggal. Nilai jawaban = nomor urut opsi (0 sampai 3),
/// makin besar berarti makin berpengalaman atau makin nyaman.
class LevelQuestion {
  const LevelQuestion({required this.text, required this.options});

  final String text;
  final List<String> options;
}

const List<LevelQuestion> levelQuestions = [
  LevelQuestion(
    text: 'Seberapa sering kamu menyelam?',
    options: [
      'Belum pernah, paling banyak snorkeling',
      'Pernah mencoba beberapa kali (misalnya Discover Scuba)',
      'Cukup rutin, beberapa kali setahun',
      'Sangat sering, menyelam sudah jadi kebiasaan',
    ],
  ),
  LevelQuestion(
    text: 'Sertifikasi selam apa yang kamu punya?',
    options: [
      'Belum punya',
      'Open Water atau setara',
      'Advanced Open Water atau setara',
      'Rescue Diver, Divemaster, atau lebih tinggi',
    ],
  ),
  LevelQuestion(
    text: 'Kira-kira sudah berapa kali menyelam?',
    options: [
      'Belum pernah',
      '1 sampai 10 kali',
      '11 sampai 50 kali',
      'Lebih dari 50 kali',
    ],
  ),
  LevelQuestion(
    text: 'Kedalaman berapa yang paling nyaman buatmu?',
    options: [
      'Dangkal saja (snorkeling atau di bawah 6 m)',
      'Sampai sekitar 12 m',
      'Sampai sekitar 18 sampai 30 m',
      'Lebih dari 30 m',
    ],
  ),
  LevelQuestion(
    text: 'Bagaimana perasaanmu terhadap arus laut?',
    options: [
      'Hanya mau perairan tenang',
      'Arus ringan masih nyaman',
      'Arus sedang masih bisa ditangani',
      'Arus kuat atau drift dive tidak masalah',
    ],
  ),
];

/// Minat yang bisa dipilih pengguna (kunci -> label tampilan).
const Map<String, String> interestLabels = {
  'snorkeling': 'Snorkeling',
  'terumbu': 'Terumbu karang berwarna',
  'bangkai_kapal': 'Bangkai kapal',
  'biota_besar': 'Biota besar (hiu, pari manta, penyu)',
  'makro': 'Biota kecil dan unik (makro)',
  'dinding': 'Dinding dan tebing karang',
};

class _Sample {
  const _Sample(this.features, this.label);

  final List<int> features;
  final SpotLevel label;
}

/// Data latih contoh buatan tim (bukan data pengguna sungguhan). Tiap baris adalah profil
/// jawaban untuk kelima pertanyaan di atas, beserta level yang wajar untuk profil itu.
const List<_Sample> _trainingSet = [
  _Sample([0, 0, 0, 0, 0], SpotLevel.pemula),
  _Sample([0, 0, 0, 1, 0], SpotLevel.pemula),
  _Sample([1, 0, 0, 1, 0], SpotLevel.pemula),
  _Sample([1, 1, 1, 1, 0], SpotLevel.pemula),
  _Sample([0, 0, 0, 0, 1], SpotLevel.pemula),
  _Sample([1, 1, 1, 1, 1], SpotLevel.pemula),
  _Sample([1, 0, 1, 1, 0], SpotLevel.pemula),
  _Sample([2, 1, 2, 2, 1], SpotLevel.menengah),
  _Sample([1, 1, 2, 2, 1], SpotLevel.menengah),
  _Sample([2, 1, 1, 2, 2], SpotLevel.menengah),
  _Sample([2, 2, 2, 2, 1], SpotLevel.menengah),
  _Sample([2, 1, 2, 1, 1], SpotLevel.menengah),
  _Sample([1, 1, 1, 2, 2], SpotLevel.menengah),
  _Sample([2, 2, 2, 3, 1], SpotLevel.menengah),
  _Sample([3, 2, 3, 3, 3], SpotLevel.lanjutan),
  _Sample([3, 3, 3, 3, 2], SpotLevel.lanjutan),
  _Sample([2, 2, 3, 3, 3], SpotLevel.lanjutan),
  _Sample([3, 2, 2, 3, 3], SpotLevel.lanjutan),
  _Sample([3, 3, 3, 3, 3], SpotLevel.lanjutan),
  _Sample([2, 3, 3, 3, 2], SpotLevel.lanjutan),
];

int get trainingSampleCount => _trainingSet.length;

/// Jumlah tetangga terdekat yang dipakai k-NN.
const int knnNeighbors = 3;

/// Hasil klasifikasi level.
class LevelPrediction {
  const LevelPrediction({
    required this.level,
    required this.confidence,
    required this.neighborLevels,
    this.ruleNote,
  });

  final SpotLevel level;

  /// Porsi suara tertimbang untuk level pemenang, 0 sampai 1.
  final double confidence;

  /// Level dari tetangga terdekat yang ikut menentukan hasil.
  final List<SpotLevel> neighborLevels;

  /// Terisi kalau aturan pengaman menimpa hasil model.
  final String? ruleNote;
}

/// Klasifikasi level pengguna dengan k-Nearest Neighbors (Machine Learning klasik, bukan LLM):
/// jawaban dijadikan vektor 5 angka, dicari 3 profil latih terdekat (jarak Euclidean), lalu
/// level ditentukan lewat suara tertimbang (bobot = 1 / (jarak + 0,1)).
/// Aturan pengaman di atas model: belum pernah selam atau belum bersertifikat tidak akan
/// dilabeli di atas Pemula.
LevelPrediction classifyLevel(List<int> answers) {
  assert(answers.length == levelQuestions.length);

  final distances = <MapEntry<double, SpotLevel>>[];
  for (final sample in _trainingSet) {
    var sum = 0.0;
    for (var i = 0; i < answers.length; i++) {
      final diff = (answers[i] - sample.features[i]).toDouble();
      sum += diff * diff;
    }
    distances.add(MapEntry(math.sqrt(sum), sample.label));
  }
  distances.sort((a, b) => a.key.compareTo(b.key));
  final nearest = distances.take(knnNeighbors).toList();

  final votes = <SpotLevel, double>{};
  var total = 0.0;
  for (final neighbor in nearest) {
    final weight = 1 / (neighbor.key + 0.1);
    votes[neighbor.value] = (votes[neighbor.value] ?? 0) + weight;
    total += weight;
  }
  var winner = SpotLevel.pemula;
  var best = -1.0;
  for (final level in SpotLevel.values) {
    final value = votes[level] ?? 0;
    if (value > best) {
      best = value;
      winner = level;
    }
  }
  final neighborLevels = [for (final n in nearest) n.value];

  if (answers[0] == 0) {
    return LevelPrediction(
      level: SpotLevel.pemula,
      confidence: 1,
      neighborLevels: neighborLevels,
      ruleNote: 'Kamu belum pernah menyelam, jadi levelmu dikunci di Pemula.',
    );
  }
  if (answers[1] == 0 && winner != SpotLevel.pemula) {
    return LevelPrediction(
      level: SpotLevel.pemula,
      confidence: 1,
      neighborLevels: neighborLevels,
      ruleNote: 'Kamu belum punya sertifikasi selam, jadi levelmu dikunci di Pemula.',
    );
  }
  return LevelPrediction(
    level: winner,
    confidence: total == 0 ? 0 : best / total,
    neighborLevels: neighborLevels,
  );
}

/// Kata kunci untuk membaca "profil minat" sebuah spot dari teks datanya.
const Map<String, List<String>> _interestKeywords = {
  'terumbu': ['terumbu karang', 'karang'],
  'bangkai_kapal': ['bangkai', 'wreck', 'kapal karam'],
  'biota_besar': ['hiu', 'pari', 'manta', 'paus', 'penyu', 'dugong', 'pelagis'],
  'makro': ['muck', 'nudibranch', 'makro', 'macro', 'kuda laut', 'seahorse', 'frogfish', 'pygmy', 'pigmy', 'mimic'],
  'dinding': ['dinding', 'tebing', 'wall', 'drop-off', 'ngarai'],
};

/// Minat yang dikandung sebuah spot (snorkeling dari jenis spot, sisanya dari kata kunci teks).
Set<String> spotInterestTags(Spot spot) {
  final tags = <String>{};
  if (spot.types.contains(SpotType.snorkeling)) tags.add('snorkeling');
  final text = [spot.name, spot.tagline, spot.summary, ...spot.biota].join(' ').toLowerCase();
  _interestKeywords.forEach((tag, keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        tags.add(tag);
        break;
      }
    }
  });
  return tags;
}

/// Satu spot beserta skor kecocokannya.
class SpotRecommendation {
  const SpotRecommendation({
    required this.spot,
    required this.score,
    required this.reasons,
  });

  final Spot spot;

  /// 0 sampai 1.
  final double score;
  final List<String> reasons;

  int get percent => (score * 100).round();
}

/// Rekomendasi berbasis konten (content-based filtering): kecocokan = 50% level + 50% kemiripan
/// minat (cosine similarity antara vektor minat pengguna dan vektor minat spot).
/// Spot dengan level di atas level pengguna tidak ditampilkan sama sekali.
List<SpotRecommendation> recommendSpots({
  required List<Spot> spots,
  required SpotLevel userLevel,
  required Set<String> interests,
}) {
  final results = <SpotRecommendation>[];
  for (final spot in spots) {
    if (spot.level.index > userLevel.index) continue;

    final gap = userLevel.index - spot.level.index;
    final levelFit = gap == 0 ? 1.0 : (gap == 1 ? 0.6 : 0.3);

    final tags = spotInterestTags(spot);
    final shared = interests.intersection(tags);
    final cosine = (interests.isEmpty || tags.isEmpty)
        ? 0.0
        : shared.length / (math.sqrt(interests.length) * math.sqrt(tags.length));

    final score = interests.isEmpty ? levelFit : 0.5 * levelFit + 0.5 * cosine;

    final reasons = <String>[
      gap == 0 ? 'Level spot sama dengan levelmu' : 'Level spot lebih mudah dari levelmu',
      if (shared.isNotEmpty)
        'Cocok dengan minat: ${[for (final key in shared) interestLabels[key] ?? key].join(', ')}',
    ];
    results.add(SpotRecommendation(spot: spot, score: score, reasons: reasons));
  }
  results.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    return byScore != 0 ? byScore : a.spot.name.compareTo(b.spot.name);
  });
  return results;
}
