import 'package:http/http.dart' as http;

import 'package:divefriend/data/models/sea_conditions.dart';
import 'package:divefriend/services/json_client.dart';

/// Kontrak sumber data gelombang. Layar hanya bergantung pada kelas ini.
abstract class MarineService {
  Future<SeaConditions> fetchToday({
    required double latitude,
    required double longitude,
  });
}

/// Gelombang dari Open-Meteo Marine (marine-api.open-meteo.com/v1/marine). Tanpa kunci API,
/// gratis untuk non-komersial dengan syarat mencantumkan sumber (dilakukan di layar).
/// timezone=auto wajib karena meminta data harian, forecast_days=1 berarti hanya hari ini.
class OpenMeteoMarineService implements MarineService {
  OpenMeteoMarineService(this._client);

  final http.Client _client;

  @override
  Future<SeaConditions> fetchToday({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      'https://marine-api.open-meteo.com/v1/marine'
      '?latitude=$latitude&longitude=$longitude'
      '&current=wave_height&daily=wave_height_max'
      '&timezone=auto&forecast_days=1',
    );
    final json = await getJsonObject(_client, uri);
    return SeaConditions.fromJson(json);
  }
}
