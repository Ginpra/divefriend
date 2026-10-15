import 'package:divefriend/data/repositories/spot_repository.dart';
import 'package:divefriend/services/auth_service.dart';

/// Kumpulan layanan yang dipakai banyak layar. Dibuat sekali di main.dart
/// lalu dioper lewat constructor, jadi mudah ditukar dengan versi palsu saat tes.
class AppServices {
  const AppServices({required this.spots, required this.auth});

  final SpotRepository spots;
  final AuthService auth;
}
