# divefriend

Project Diving Mobile Teori

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

flutter pub add sqflite path path_provider crypto shared_preferences image_picker local_auth 
flutter pub add http
flutter pub add sensors_plus geolocator url_launcher
flutter pub add flutter_map latlong2 flutter_local_notifications timezone
flutter pub add web3dart

buat file di lib > config > secrets.dart isinya = 
class Secrets {
  static const String supabaseUrl = 'supabase url';
  static const String supabaseAnonKey = 'supabase anon key';
  static const String geminiApiKey = 'api key gemini';
  static const String sepoliaRpcUrl = '';
  static const String sepoliaPrivateKey = '';
}

lib/
├─ main.dart            → titik awal: siapkan DB, HTTP, semua "service", cek session
├─ app.dart             → widget akar (MaterialApp), tema, Splash → Login/Beranda
├─ app_services.dart    → "kotak peralatan": kumpulan service yang dioper ke tiap layar
├─ config/secrets.dart  → kunci API (TIDAK ada di Git, jadi memang tidak ketemu)
│
├─ core/                → LOGIKA MURNI (tanpa tampilan): rumus & aturan
│   ├─ app_theme.dart       warna, font, spasi (AppColors, AppSpace, AppFonts)
│   ├─ level_classifier.dart  k-NN level penyelam
│   ├─ log_chain.dart / anchor_check.dart   hash chain & cek blockchain
│   ├─ compass_math.dart, geo_math.dart     arah & jarak GPS
│   ├─ shake_detector.dart, vec3.dart       deteksi goyang (sensor)
│   ├─ encounter_grade.dart                 grade game (50/30/15/5)
│   ├─ time_zones.dart, booking_math.dart, validators.dart, formatters.dart
│   └─ widgets/             widget bersama (logo, kartu, banner, dll)
│
├─ data/                → DATA
│   ├─ local/app_database.dart     SQLite: bikin tabel
│   ├─ models/                     class data (Spot, AppUser, Booking, LogEntry, ...)
│   ├─ repositories/               akses DB: interface + versi sqlite_*
│   ├─ remote/                     Supabase (spot_remote_source.dart, supabase_config.dart)
│   └─ seed/                       data awal 15 spot
│
├─ services/            → KERJA DI LUAR LAYAR
│   ├─ auth_service.dart, password_hasher.dart, biometric_service.dart   login
│   ├─ marine_service.dart (Open-Meteo), exchange_rate_service.dart (Frankfurter),
│   │  gemini_service.dart (Gemini), blockchain_service.dart (Sepolia)   API
│   ├─ sensor_service.dart, location_service.dart                        sensor & GPS
│   ├─ spot_sync_service.dart       Supabase → SQLite
│   └─ notification_service.dart, logbook_service.dart, dll
│
└─ features/            → LAYAR (UI), satu folder per fitur
    ├─ splash/, auth/ (login, register), navigation/ (main_shell)
    ├─ home/, spot/, map/, booking/, converter/, direction/
    ├─ logbook/, game/, ai/, preferences/, profile/