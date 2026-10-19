import 'package:divefriend/data/models/spot.dart';

/// Mengubah satu baris tabel `spots` dari Supabase (JSON) menjadi [Spot].
/// Nama kolom sama dengan di SQLite lokal (snake_case). Kolom array (types, biota, sources) datang
/// sebagai daftar JSON. Baris yang tidak lengkap atau berisi nilai tidak dikenal melempar
/// [FormatException], supaya sinkronisasi dibatalkan dan data lokal yang lama tetap aman.
Spot spotFromJson(Map<String, dynamic> json) {
  String requireString(String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw FormatException('Kolom $key kosong atau bukan teks');
  }

  String? optionalString(String key) {
    final value = json[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  List<String> stringList(String key, {required bool required}) {
    final value = json[key];
    if (value == null) {
      if (required) throw FormatException('Kolom $key kosong');
      return const [];
    }
    if (value is! List || value.any((item) => item is! String)) {
      throw FormatException('Kolom $key bukan daftar teks');
    }
    final list = value.cast<String>();
    if (required && list.isEmpty) throw FormatException('Kolom $key kosong');
    return list;
  }

  final levelName = requireString('level');
  final level = SpotLevel.values.asNameMap()[levelName];
  if (level == null) throw FormatException('Level tidak dikenal: $levelName');

  final types = stringList('types', required: true).map((name) {
    final type = SpotType.values.asNameMap()[name];
    if (type == null) throw FormatException('Jenis tidak dikenal: $name');
    return type;
  }).toList();

  final price = json['price_idr'];
  final latitude = json['latitude'];
  final longitude = json['longitude'];
  final photoUrl = optionalString('photo_url');

  return Spot(
    id: requireString('id'),
    name: requireString('name'),
    region: requireString('region'),
    level: level,
    levelBasis: requireString('level_basis'),
    types: types,
    tagline: requireString('tagline'),
    summary: requireString('summary'),
    depthText: optionalString('depth_text'),
    bestSeason: optionalString('best_season'),
    biota: stringList('biota', required: false),
    priceEstimateIdr: price is num ? price.toInt() : null,
    latitude: latitude is num ? latitude.toDouble() : null,
    longitude: longitude is num ? longitude.toDouble() : null,
    timeZoneLabel: optionalString('time_zone'),
    sources: stringList('sources', required: true),
    photo: photoUrl == null
        ? null
        : SpotPhoto(
            url: photoUrl,
            credit: optionalString('photo_credit'),
            license: optionalString('photo_license'),
            sourceUrl: optionalString('photo_source_url'),
          ),
  );
}
