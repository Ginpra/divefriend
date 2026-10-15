enum SpotLevel {
  pemula('Pemula'),
  menengah('Menengah'),
  lanjutan('Lanjutan');

  const SpotLevel(this.label);
  final String label;
}

enum SpotType {
  snorkeling('Snorkeling'),
  scuba('Scuba');

  const SpotType(this.label);
  final String label;
}

/// Satu spot selam. Kolom mengikuti rencana tabel `spots` (Tahap 3).
/// Field opsional bernilai null = data belum tersedia (UI menampilkan "tidak tersedia").
class Spot {
  const Spot({
    required this.id,
    required this.name,
    required this.region,
    required this.level,
    required this.types,
    this.depthMeters,
    this.bestSeason,
    this.biota = const [],
    this.priceEstimateIdr,
    this.latitude,
    this.longitude,
    this.timeZoneLabel,
    this.source,
    this.isDummy = false,
  });

  final String id;
  final String name;
  final String region;
  final SpotLevel level;
  final List<SpotType> types;
  final double? depthMeters;
  final String? bestSeason;
  final List<String> biota;
  final int? priceEstimateIdr;
  final double? latitude;
  final double? longitude;
  final String? timeZoneLabel;
  final String? source;

  /// true = data placeholder untuk uji tampilan, bukan data tersumber.
  final bool isDummy;
}
