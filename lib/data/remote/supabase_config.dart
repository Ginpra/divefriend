/// Alamat proyek Supabase dan kunci publiknya (dari lib/config/secrets.dart).
/// Kunci yang dipakai HP hanya kunci PUBLIK (publishable atau anon). Kunci rahasia (secret atau
/// service_role) tidak boleh pernah ada di aplikasi.
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.apiKey});

  final String url;
  final String apiKey;

  /// False kalau secrets.dart belum diisi (masih berisi tulisan ISI_DI_SECRETS_DART).
  bool get isConfigured => url.startsWith('https://') && apiKey.isNotEmpty && !apiKey.startsWith('ISI_');

  /// Alamat dasar REST API: https://<project>.supabase.co/rest/v1
  String get restBase {
    final trimmed = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    return '$trimmed/rest/v1';
  }
}
