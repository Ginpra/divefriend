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
}