import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:divefriend/app.dart';
import 'package:divefriend/app_services.dart';
import 'package:divefriend/config/secrets.dart';
import 'package:divefriend/data/local/app_database.dart';
import 'package:divefriend/data/remote/spot_remote_source.dart';
import 'package:divefriend/data/remote/supabase_config.dart';
import 'package:divefriend/data/repositories/sqlite_booking_repository.dart';
import 'package:divefriend/data/repositories/sqlite_logbook_repository.dart';
import 'package:divefriend/data/repositories/sqlite_spot_repository.dart';
import 'package:divefriend/data/repositories/sqlite_user_repository.dart';
import 'package:divefriend/services/auth_service.dart';
import 'package:divefriend/services/biometric_service.dart';
import 'package:divefriend/services/exchange_rate_service.dart';
import 'package:divefriend/services/gemini_service.dart';
import 'package:divefriend/services/location_service.dart';
import 'package:divefriend/services/logbook_service.dart';
import 'package:divefriend/services/map_launcher.dart';
import 'package:divefriend/services/marine_service.dart';
import 'package:divefriend/services/notification_service.dart';
import 'package:divefriend/services/sensor_service.dart';
import 'package:divefriend/services/spot_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final spotRepository = SqliteSpotRepository(AppDatabase.instance);
  await spotRepository.ensureSeeded();

  // Satu klien HTTP dipakai bersama oleh semua layanan internet.
  final httpClient = http.Client();

  // Supabase hanya dipakai kalau lib/config/secrets.dart sudah diisi, kalau belum aplikasi tetap
  // jalan dengan data spot lokal.
  const supabaseConfig = SupabaseConfig(
    url: Secrets.supabaseUrl,
    apiKey: Secrets.supabaseAnonKey,
  );
  final spotRemote = supabaseConfig.isConfigured ? SupabaseSpotSource(httpClient, supabaseConfig) : null;

  final services = AppServices(
    spots: spotRepository,
    auth: AuthService(SqliteUserRepository(AppDatabase.instance), BiometricService()),
    rates: FrankfurterRateService(httpClient),
    marine: OpenMeteoMarineService(httpClient),
    location: GeolocatorLocationService(),
    sensors: DeviceSensorService(),
    maps: UrlMapLauncher(),
    logbook: LogbookService(SqliteLogbookRepository(AppDatabase.instance)),
    sync: SpotSyncService(remote: spotRemote, local: spotRepository),
    bookings: SqliteBookingRepository(AppDatabase.instance),
    notifications: LocalNotificationService(),
    gemini: HttpGeminiService(httpClient, apiKey: Secrets.geminiApiKey),
  );

  // Kalau session masih ada, langsung ke Beranda tanpa login ulang.
  final savedUser = await services.auth.restoreSession();
  runApp(DiveFriendApp(services: services, startLoggedIn: savedUser != null));
}
