import 'package:http/http.dart' as http;

import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/data/remote/spot_json.dart';
import 'package:divefriend/data/remote/supabase_config.dart';
import 'package:divefriend/services/api_failure.dart';
import 'package:divefriend/services/json_client.dart';

/// Kontrak sumber data spot online. Tes memakai versi palsu supaya tidak butuh internet.
abstract class SpotRemoteSource {
  /// Seluruh spot dari server. Melempar [ApiFailure] kalau gagal.
  Future<List<Spot>> fetchSpots();
}

/// Data spot dari tabel `spots` di Supabase lewat REST API (PostgREST), memakai paket http.
/// Hanya membaca (GET). Kunci publik dikirim di header `apikey` SAJA. Kunci publishable
/// (sb_publishable_...) tidak boleh dikirim juga di header Authorization, kalau dikirim Supabase
/// menolaknya dengan "Invalid JWT".
class SupabaseSpotSource implements SpotRemoteSource {
  SupabaseSpotSource(this._client, this._config);

  final http.Client _client;
  final SupabaseConfig _config;

  @override
  Future<List<Spot>> fetchSpots() async {
    final uri = Uri.parse('${_config.restBase}/spots?select=*&order=name.asc');
    final rows = await getJsonList(_client, uri, headers: {'apikey': _config.apiKey});
    try {
      return rows.map((row) {
        if (row is! Map<String, dynamic>) throw const FormatException('Baris spot bukan objek');
        return spotFromJson(row);
      }).toList();
    } on FormatException {
      throw const ApiFailure(ApiFailureKind.badData);
    }
  }
}
