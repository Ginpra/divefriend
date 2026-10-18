import 'package:geolocator/geolocator.dart';

import 'package:divefriend/data/models/geo_point.dart';

enum LocationFailureKind { serviceDisabled, permissionDenied, permissionDeniedForever }

/// Alasan posisi GPS tidak bisa dipakai. Dikirim lewat error pada stream posisi.
class LocationFailure implements Exception {
  const LocationFailure(this.kind);

  final LocationFailureKind kind;
}

/// Kontrak sumber posisi pengguna. Layar hanya bergantung pada kelas ini, jadi tes bisa memakai versi palsu.
abstract class LocationService {
  /// Aliran posisi terbaru. Berakhir dengan [LocationFailure] kalau GPS mati atau izin ditolak.
  Stream<GeoPoint> positions();

  /// Membuka pengaturan yang relevan: pengaturan lokasi kalau GPS mati, pengaturan aplikasi kalau izin ditolak permanen.
  Future<void> openSettings(LocationFailureKind kind);
}

/// Posisi dari GPS lewat paket geolocator. Urutannya: cek GPS menyala, cek atau minta izin,
/// lalu mengalirkan posisi. Posisi baru dikirim kalau pengguna bergerak minimal 5 meter.
class GeolocatorLocationService implements LocationService {
  static final LocationSettings _settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5,
  );

  @override
  Stream<GeoPoint> positions() async* {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(LocationFailureKind.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(LocationFailureKind.permissionDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(LocationFailureKind.permissionDeniedForever);
    }

    yield* Geolocator.getPositionStream(locationSettings: _settings).map(
      (position) => GeoPoint(position.latitude, position.longitude),
    );
  }

  @override
  Future<void> openSettings(LocationFailureKind kind) async {
    if (kind == LocationFailureKind.serviceDisabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}
