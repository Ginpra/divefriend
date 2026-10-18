/// Kondisi gelombang laut hari ini dari Open-Meteo Marine.
/// Nilai null berarti model tidak punya data untuk titik itu (misalnya titiknya jatuh di darat).
class SeaConditions {
  const SeaConditions({this.currentWaveHeightM, this.maxWaveHeightTodayM});

  /// Tinggi gelombang signifikan saat ini, dalam meter.
  final double? currentWaveHeightM;

  /// Tinggi gelombang tertinggi hari ini, dalam meter.
  final double? maxWaveHeightTodayM;

  bool get hasData => currentWaveHeightM != null || maxWaveHeightTodayM != null;

  /// Tidak pernah melempar error: bagian yang tidak ada atau bukan angka jadi null,
  /// lalu layar menampilkan "tidak tersedia".
  factory SeaConditions.fromJson(Map<String, dynamic> json) {
    return SeaConditions(
      currentWaveHeightM: _readNumber(json['current'], 'wave_height'),
      maxWaveHeightTodayM: _readFirstOfList(json['daily'], 'wave_height_max'),
    );
  }

  static double? _readNumber(Object? section, String key) {
    if (section is! Map) return null;
    final value = section[key];
    return value is num ? value.toDouble() : null;
  }

  static double? _readFirstOfList(Object? section, String key) {
    if (section is! Map) return null;
    final values = section[key];
    if (values is! List || values.isEmpty) return null;
    final first = values.first;
    return first is num ? first.toDouble() : null;
  }
}
