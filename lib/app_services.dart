import 'package:divefriend/data/repositories/spot_repository.dart';
import 'package:divefriend/services/auth_service.dart';
import 'package:divefriend/services/exchange_rate_service.dart';
import 'package:divefriend/services/location_service.dart';
import 'package:divefriend/services/logbook_service.dart';
import 'package:divefriend/services/map_launcher.dart';
import 'package:divefriend/services/marine_service.dart';
import 'package:divefriend/services/sensor_service.dart';
import 'package:divefriend/services/spot_sync_service.dart';

/// Kumpulan layanan yang dipakai banyak layar. Dibuat sekali di main.dart
/// lalu dioper lewat constructor, jadi mudah ditukar dengan versi palsu saat tes.
class AppServices {
  const AppServices({
    required this.spots,
    required this.auth,
    required this.rates,
    required this.marine,
    required this.location,
    required this.sensors,
    required this.maps,
    required this.logbook,
    required this.sync,
  });

  final SpotRepository spots;
  final AuthService auth;
  final ExchangeRateService rates;
  final MarineService marine;
  final LocationService location;
  final SensorService sensors;
  final MapLauncher maps;
  final LogbookService logbook;
  final SpotSyncService sync;
}
