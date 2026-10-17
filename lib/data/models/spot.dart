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

/// Foto spot. Kredit dan lisensi opsional: isi keduanya bila foto berlisensi terbuka
/// yang mewajibkan atribusi (contoh CC BY-SA), kosongkan bila tidak perlu ditampilkan.
class SpotPhoto {
  const SpotPhoto({
    required this.url,
    this.credit,
    this.license,
    this.sourceUrl,
  });

  final String url;
  final String? credit;
  final String? license;
  final String? sourceUrl;
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
    required this.tagline,
    required this.summary,
    required this.sources,
    this.depthText,
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

  /// Satu kalimat pembuka yang muncul di kartu dan di atas halaman detail.
  final String tagline;

  /// Deskripsi lengkap. Paragraf dipisah baris kosong (dua kali newline).
  final String summary;

  /// Daftar sumber data spot ini (nama + alamat), wajib minimal satu.
  final List<String> sources;

  /// Kedalaman dalam bentuk teks (contoh: "Sekitar 5-30 m"), karena tiap sumber
  /// menyebut kedalaman dengan cara berbeda (dinding, bangkai kapal, rentang).
  final String? depthText;
  final String? bestSeason;
  final List<String> biota;
  final int? priceEstimateIdr;

  /// Titik pusat kawasan, BUKAN lokasi titik selam tertentu.
  final double? latitude;
  final double? longitude;
  final String? timeZoneLabel;
  final SpotPhoto? photo;
}
