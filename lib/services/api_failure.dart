enum ApiFailureKind { offline, server, badData }

/// Kegagalan panggilan API yang sudah dikelompokkan, supaya layar bisa menampilkan
/// pesan yang jelas: tidak ada koneksi, layanan bermasalah, atau data tidak terbaca.
class ApiFailure implements Exception {
  const ApiFailure(this.kind);

  final ApiFailureKind kind;
}

/// Kalimat untuk pengguna. [feature] contoh: "gelombang" atau "kurs".
String failureText(Object error, String feature) {
  if (error is ApiFailure) {
    return switch (error.kind) {
      ApiFailureKind.offline =>
        'Tidak ada koneksi internet, data $feature belum bisa dimuat.',
      ApiFailureKind.server =>
        'Layanan $feature sedang bermasalah. Coba lagi beberapa saat lagi.',
      ApiFailureKind.badData => 'Data $feature yang diterima tidak bisa dibaca.',
    };
  }
  return 'Terjadi kesalahan saat memuat data $feature.';
}
