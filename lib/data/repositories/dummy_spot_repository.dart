import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/data/repositories/spot_repository.dart';

/// Data DUMMY untuk uji tampilan Tahap 1.
/// Nama dan wilayah adalah lokasi selam yang dikenal. Level dan jenis hanya placeholder
/// agar filter bisa diuji, BUKAN penilaian resmi. Kedalaman, harga, koordinat, musim,
/// biota, dan sumber sengaja kosong (null) karena belum dikurasi; diisi di Tahap 3.
class DummySpotRepository implements SpotRepository {
  DummySpotRepository({this.simulatedDelay = const Duration(milliseconds: 300)});

  /// Jeda buatan supaya state "memuat" terlihat. Tes memakai Duration.zero.
  final Duration simulatedDelay;

  static const List<Spot> _spots = [
    Spot(
      id: 'bunaken',
      name: 'Bunaken',
      region: 'Sulawesi Utara',
      level: SpotLevel.menengah,
      types: [SpotType.scuba, SpotType.snorkeling],
      isDummy: true,
    ),
    Spot(
      id: 'raja-ampat',
      name: 'Raja Ampat',
      region: 'Papua Barat Daya',
      level: SpotLevel.lanjutan,
      types: [SpotType.scuba],
      isDummy: true,
    ),
    Spot(
      id: 'komodo',
      name: 'Taman Nasional Komodo',
      region: 'Nusa Tenggara Timur',
      level: SpotLevel.lanjutan,
      types: [SpotType.scuba],
      isDummy: true,
    ),
    Spot(
      id: 'wakatobi',
      name: 'Wakatobi',
      region: 'Sulawesi Tenggara',
      level: SpotLevel.pemula,
      types: [SpotType.snorkeling, SpotType.scuba],
      isDummy: true,
    ),
    Spot(
      id: 'tulamben',
      name: 'Tulamben',
      region: 'Bali',
      level: SpotLevel.pemula,
      types: [SpotType.snorkeling, SpotType.scuba],
      isDummy: true,
    ),
    Spot(
      id: 'pulau-weh',
      name: 'Pulau Weh',
      region: 'Aceh',
      level: SpotLevel.menengah,
      types: [SpotType.scuba],
      isDummy: true,
    ),
  ];

  @override
  Future<List<Spot>> getSpots({String query = '', SpotLevel? level}) async {
    await Future<void>.delayed(simulatedDelay);
    final normalizedQuery = query.trim().toLowerCase();

    return _spots.where((spot) {
      final matchesLevel = level == null || spot.level == level;
      final matchesQuery = normalizedQuery.isEmpty ||
          spot.name.toLowerCase().contains(normalizedQuery) ||
          spot.region.toLowerCase().contains(normalizedQuery);
      return matchesLevel && matchesQuery;
    }).toList();
  }
}
