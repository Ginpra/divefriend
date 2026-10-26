import 'dart:async';

import 'package:flutter/material.dart';

import 'package:divefriend/core/app_theme.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/geo_math.dart';
import 'package:divefriend/core/widgets/inline_notice.dart';
import 'package:divefriend/core/widgets/section_card.dart';
import 'package:divefriend/core/widgets/state_message.dart';
import 'package:divefriend/data/models/geo_point.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/features/direction/compass_arrow.dart';
import 'package:divefriend/features/direction/route_plan_card.dart';
import 'package:divefriend/services/location_service.dart';

/// Arah ke Spot: panah kompas besar yang menunjuk ke spot, ditambah jarak dari posisi GPS pengguna.
/// Menggabungkan tiga sumber: GPS (posisi), sensor kompas (arah HP), dan koordinat spot.
/// Arah panah = arah spot dari posisi pengguna dikurangi arah yang sedang dihadap HP.
class DirectionScreen extends StatefulWidget {
  const DirectionScreen({super.key, required this.spot, required this.services});

  final Spot spot;
  final AppServices services;

  @override
  State<DirectionScreen> createState() => _DirectionScreenState();
}

class _DirectionScreenState extends State<DirectionScreen> {
  StreamSubscription<GeoPoint>? _positionSubscription;
  StreamSubscription<double>? _headingSubscription;
  GeoPoint? _position;
  double? _heading;
  Object? _locationError;
  bool _compassUnavailable = false;

  GeoPoint? get _target {
    final latitude = widget.spot.latitude;
    final longitude = widget.spot.longitude;
    if (latitude == null || longitude == null) return null;
    return GeoPoint(latitude, longitude);
  }

  @override
  void initState() {
    super.initState();
    if (_target == null) return;
    _listenToPosition();
    _listenToHeading();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _headingSubscription?.cancel();
    super.dispose();
  }

  void _listenToPosition() {
    _positionSubscription?.cancel();
    _positionSubscription = widget.services.location.positions().listen(
      (point) {
        setState(() {
          _position = point;
        });
      },
      onError: (Object error) {
        setState(() {
          _locationError = error;
        });
      },
    );
  }

  void _listenToHeading() {
    _headingSubscription = widget.services.sensors.headings().listen(
      (heading) {
        setState(() {
          _heading = heading;
        });
      },
      onError: (Object error) {
        setState(() {
          _compassUnavailable = true;
        });
      },
    );
  }

  void _retryLocation() {
    setState(() {
      _locationError = null;
      _position = null;
    });
    _listenToPosition();
  }

  Future<void> _openSettings(LocationFailureKind kind) {
    return widget.services.location.openSettings(kind);
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;
    return Scaffold(
      appBar: AppBar(title: const Text('Arah ke Spot')),
      body: target == null
          ? const StateMessage(
              icon: Icons.location_off_outlined,
              title: 'Koordinat tidak tersedia',
              message: 'Spot ini belum punya koordinat, jadi arah dan jarak belum bisa dihitung.',
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset(context)),
              children: [
                SectionCard(
                  icon: Icons.explore,
                  title: 'Arah lurus ke ${widget.spot.name}',
                  child: Center(child: _buildCompass(target)),
                ),
                RoutePlanCard(spot: widget.spot, maps: widget.services.maps),
                _buildNotes(),
              ],
            ),
    );
  }

  Widget _buildCompass(GeoPoint target) {
    final error = _locationError;
    if (error != null) return _buildLocationError(error);

    final position = _position;
    if (position == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'Mencari posisi GPS. Di dalam ruangan bisa lebih lama, coba pindah ke tempat terbuka.',
              ),
            ),
          ],
        ),
      );
    }

    final distance = distanceMeters(
      position.latitude,
      position.longitude,
      target.latitude,
      target.longitude,
    );
    final bearing = bearingDegrees(
      position.latitude,
      position.longitude,
      target.latitude,
      target.longitude,
    );
    final heading = _heading;
    final arrowAngle = heading == null ? null : normalizeDegrees(bearing - heading);

    return Column(
      children: [
        CompassArrow(angleDegrees: arrowAngle),
        const SizedBox(height: 12),
        Text(
          formatDistance(distance),
          key: const Key('direction_distance'),
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        Text(
          'Arah ke spot: ${bearing.round()}° (${cardinalLabel(bearing)})',
          key: const Key('direction_bearing'),
        ),
        const SizedBox(height: 8),
        if (_compassUnavailable)
          const InlineNotice(
            icon: Icons.sensors_off,
            message:
                'HP ini tidak punya sensor kompas yang bisa dibaca, jadi panah belum bisa tampil. Jarak dan arah derajat tetap bisa dipakai.',
          )
        else if (heading == null)
          const Text('Menunggu sensor kompas', style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildLocationError(Object error) {
    final kind = error is LocationFailure ? error.kind : null;
    final message = switch (kind) {
      LocationFailureKind.serviceDisabled =>
        'GPS di HP sedang mati. Nyalakan layanan lokasi untuk melihat jarak ke spot.',
      LocationFailureKind.permissionDenied =>
        'Izin lokasi belum diberikan, jadi jarak ke spot belum bisa dihitung.',
      LocationFailureKind.permissionDeniedForever =>
        'Izin lokasi ditolak permanen. Aktifkan lewat pengaturan aplikasi supaya jarak ke spot bisa dihitung.',
      null => 'Posisi GPS tidak bisa dibaca saat ini.',
    };
    final needsSettings = kind == LocationFailureKind.serviceDisabled ||
        kind == LocationFailureKind.permissionDeniedForever;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InlineNotice(
          icon: Icons.location_off_outlined,
          message: message,
          onRetry: _retryLocation,
        ),
        if (needsSettings && kind != null)
          OutlinedButton(
            onPressed: () => _openSettings(kind),
            child: const Text('Buka pengaturan'),
          ),
      ],
    );
  }

  Widget _buildNotes() {
    return const SectionCard(
      icon: Icons.info_outline,
      title: 'Catatan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Koordinat spot adalah titik pusat kawasan, bukan titik selam. Jarak dan arah di layar ini '
            'hanya perkiraan kasar untuk membayangkan lokasi, bukan petunjuk pelayaran. Untuk menuju '
            'lokasi selam, ikuti arahan operator selam atau instruktur bersertifikat.',
            textAlign: TextAlign.justify,
            style: TextStyle(fontSize: 12, height: 1.4),
          ),
          SizedBox(height: 8),
          Text(
            'Kompas memakai sensor magnetik HP. Jauhkan HP dari benda logam atau magnet, dan kalau panah '
            'terasa melenceng, gerakkan HP membentuk angka 8 beberapa kali.',
            textAlign: TextAlign.justify,
            style: TextStyle(fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
