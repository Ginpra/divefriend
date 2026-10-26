import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/core/level_classifier.dart';
import 'package:divefriend/data/models/spot.dart';

Spot _spot(String id, SpotLevel level, {String summary = '', List<SpotType> types = const [SpotType.scuba]}) {
  return Spot(
    id: id,
    name: 'Spot $id',
    region: 'Wilayah',
    level: level,
    levelBasis: 'Contoh',
    types: types,
    tagline: 'Contoh',
    summary: summary,
    sources: const ['Contoh'],
  );
}

void main() {
  group('classifyLevel', () {
    test('belum pernah menyelam selalu Pemula', () {
      final result = classifyLevel([0, 0, 0, 0, 0]);
      expect(result.level, SpotLevel.pemula);
      expect(result.ruleNote, isNotNull);
    });

    test('profil sangat berpengalaman menjadi Lanjutan', () {
      expect(classifyLevel([3, 3, 3, 3, 3]).level, SpotLevel.lanjutan);
    });

    test('profil pertengahan menjadi Menengah', () {
      expect(classifyLevel([2, 1, 2, 2, 1]).level, SpotLevel.menengah);
    });

    test('tanpa sertifikasi tidak dilabeli di atas Pemula', () {
      final result = classifyLevel([3, 0, 3, 3, 3]);
      expect(result.level, SpotLevel.pemula);
      expect(result.ruleNote, isNotNull);
    });

    test('keyakinan berada di antara 0 dan 1', () {
      final result = classifyLevel([2, 2, 2, 2, 2]);
      expect(result.confidence, inInclusiveRange(0, 1));
      expect(result.neighborLevels.length, knnNeighbors);
    });
  });

  group('recommendSpots', () {
    test('spot di atas level pengguna tidak ikut direkomendasikan', () {
      final spots = [
        _spot('a', SpotLevel.pemula),
        _spot('b', SpotLevel.menengah),
        _spot('c', SpotLevel.lanjutan),
      ];
      final result = recommendSpots(spots: spots, userLevel: SpotLevel.menengah, interests: {});
      expect(result.map((item) => item.spot.id), containsAll(['a', 'b']));
      expect(result.map((item) => item.spot.id), isNot(contains('c')));
    });

    test('minat yang cocok menaikkan urutan', () {
      final spots = [
        _spot('polos', SpotLevel.pemula, summary: 'Perairan tenang.'),
        _spot('kapal', SpotLevel.pemula, summary: 'Ada bangkai kapal yang indah.'),
      ];
      final result = recommendSpots(
        spots: spots,
        userLevel: SpotLevel.pemula,
        interests: {'bangkai_kapal'},
      );
      expect(result.first.spot.id, 'kapal');
      expect(result.first.reasons.length, 2);
    });

    test('skor selalu 0 sampai 1', () {
      final result = recommendSpots(
        spots: [_spot('a', SpotLevel.pemula, types: const [SpotType.snorkeling])],
        userLevel: SpotLevel.lanjutan,
        interests: {'snorkeling', 'makro'},
      );
      expect(result.single.score, inInclusiveRange(0, 1));
    });
  });
}
