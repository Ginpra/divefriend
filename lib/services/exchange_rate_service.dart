import 'package:http/http.dart' as http;

import 'package:divefriend/core/currencies.dart';
import 'package:divefriend/data/models/exchange_rates.dart';
import 'package:divefriend/services/api_failure.dart';
import 'package:divefriend/services/json_client.dart';

/// Kontrak sumber kurs. Layar hanya bergantung pada kelas ini, jadi tes bisa memakai versi palsu.
abstract class ExchangeRateService {
  Future<ExchangeRates> fetchLatest({bool forceRefresh = false});
}

/// Kurs dari Frankfurter v1 (api.frankfurter.dev/v1/latest). Tanpa kunci API.
/// Kurs hanya berubah sekali per hari kerja, jadi hasilnya disimpan satu jam di memori
/// dan dipakai bersama oleh Detail Spot dan layar Konversi.
class FrankfurterRateService implements ExchangeRateService {
  FrankfurterRateService(this._client);

  final http.Client _client;

  static const Duration _cacheLifetime = Duration(hours: 1);

  // Euro tidak perlu diminta karena sudah menjadi mata uang dasar.
  static final Uri _latestUri = Uri.parse(
    'https://api.frankfurter.dev/v1/latest?symbols='
    '${supportedCurrencies.map((c) => c.code).where((code) => code != 'EUR').join(',')}',
  );

  ExchangeRates? _cached;
  DateTime? _cachedAt;

  @override
  Future<ExchangeRates> fetchLatest({bool forceRefresh = false}) async {
    final cached = _cached;
    final cachedAt = _cachedAt;
    if (!forceRefresh &&
        cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheLifetime) {
      return cached;
    }

    final json = await getJsonObject(_client, _latestUri);
    final ExchangeRates rates;
    try {
      rates = ExchangeRates.fromJson(json);
    } on FormatException {
      throw const ApiFailure(ApiFailureKind.badData);
    }
    _cached = rates;
    _cachedAt = DateTime.now();
    return rates;
  }
}
