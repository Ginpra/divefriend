import 'package:url_launcher/url_launcher.dart';

import 'package:divefriend/data/models/geo_point.dart';

/// Alamat Google Maps untuk menandai satu titik (format "Maps URLs": api=1 dan query berisi lintang,bujur).
/// Di HP yang punya aplikasi Google Maps, alamat ini dibuka di aplikasi tersebut, kalau tidak ada dibuka di browser.
Uri mapsUri(GeoPoint point) {
  return Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': '${point.latitude},${point.longitude}',
  });
}

/// Alamat Google Maps untuk rute (aksi "dir" di Maps URLs, tanpa kunci API).
/// [origin] kosong berarti mulai dari lokasi pengguna saat ini. [destination] dan [origin] boleh
/// berupa nama tempat atau "lintang,bujur".
Uri directionsUri({String? origin, required String destination}) {
  return Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'origin': ?origin,
    'destination': destination,
  });
}

/// Kontrak pembuka aplikasi peta. Tes memakai versi palsu supaya tidak benar-benar membuka aplikasi.
abstract class MapLauncher {
  /// Menandai satu titik di peta. True kalau berhasil membuka.
  Future<bool> open(GeoPoint point);

  /// Membuka rute ke [destination]. [origin] kosong berarti dari lokasi pengguna. True kalau berhasil membuka.
  Future<bool> openDirections({String? origin, required String destination});
}

class UrlMapLauncher implements MapLauncher {
  @override
  Future<bool> open(GeoPoint point) => _launch(mapsUri(point));

  @override
  Future<bool> openDirections({String? origin, required String destination}) {
    return _launch(directionsUri(origin: origin, destination: destination));
  }

  Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}
