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

/// Foto spot beserta atribusinya (wajib untuk gambar berlisensi terbuka).
class SpotPhoto {
  const SpotPhoto({
    required this.url,
    required this.credit,
    required this.license,
    required this.sourceUrl,
  });

  final String url;
  final String credit;
  final String license;
  final String sourceUrl;
}

/// Satu spot selam. Field opsional bernilai null = data belum tersedia
/// (layar menampilkan "tidak tersedia", tidak pernah diisi angka karangan).
class Spot {
  const Spot({
    required this.id,
    required this.name,
    required this.region,
    required this.level,
    required this.levelBasis,
    required this.types,
    required this.sources,
    this.summary,
    this.depthMeters,
    this.bestSeason,
    this.biota = const [],
    this.priceEstimateIdr,
    this.latitude,
    this.longitude,
    this.timeZoneLabel,
    this.photo,
  });

  final String id;
  final String name;
  final String region;
  final SpotLevel level;

  /// Dasar penentuan level. Level adalah estimasi tim, bukan standar resmi.
  final String levelBasis;
  final List<SpotType> types;

  /// Daftar sumber data spot ini (nama + alamat), wajib minimal satu.
  final List<String> sources;
  final String? summary;
  final double? depthMeters;
  final String? bestSeason;
  final List<String> biota;
  final int? priceEstimateIdr;

  /// Titik pusat kawasan, BUKAN lokasi titik selam tertentu.
  final double? latitude;
  final double? longitude;
  final String? timeZoneLabel;
  final SpotPhoto? photo;
}
