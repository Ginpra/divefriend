/// Pintu masuk menuju sebuah spot: tempat terakhir yang bisa dicapai lewat darat (bandara, pelabuhan, atau kota),
/// sebelum perjalanan dilanjutkan dengan kapal ke spot.
///
/// Koordinat spot adalah titik pusat kawasan dan banyak yang jatuh di tengah laut, jadi Google Maps tidak bisa
/// membuat rute ke sana. Rute dihitung sampai pintu masuk ini, lalu [steps] menjelaskan sisanya.
class AccessPoint {
  const AccessPoint({
    required this.name,
    required this.mapsQuery,
    required this.steps,
    required this.sources,
  });

  /// Nama untuk ditampilkan, contoh "Bandara Domine Eduard Osok, Sorong".
  final String name;

  /// Teks tujuan yang dikirim ke Google Maps (nama tempat atau "lintang,bujur").
  final String mapsQuery;

  /// Penjelasan singkat sisa perjalanan dari pintu masuk sampai ke spot.
  final String steps;

  /// Sumber penjelasan di atas.
  final List<String> sources;
}
