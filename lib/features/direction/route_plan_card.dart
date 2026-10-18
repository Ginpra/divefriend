import 'package:flutter/material.dart';

import 'package:divefriend/core/widgets/section_card.dart';
import 'package:divefriend/data/models/access_point.dart';
import 'package:divefriend/data/models/geo_point.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/data/seed/access_points.dart';
import 'package:divefriend/services/map_launcher.dart';

/// Rencana perjalanan ke spot: pintu masuk terdekat, langkah sisa perjalanan, dan tombol membuka
/// rute di Google Maps. Rute selalu dimulai dari lokasi pengguna saat ini. Rute Google Maps dihitung sampai pintu masuk, karena
/// titik pusat spot biasanya ada di laut dan tidak bisa dirutekan lewat jalan atau penyeberangan.
class RoutePlanCard extends StatefulWidget {
  const RoutePlanCard({super.key, required this.spot, required this.maps});

  final Spot spot;
  final MapLauncher maps;

  @override
  State<RoutePlanCard> createState() => _RoutePlanCardState();
}

class _RoutePlanCardState extends State<RoutePlanCard> {
  AccessPoint? get _accessPoint => accessPointsBySpotId[widget.spot.id];

  Future<void> _openRoute(AccessPoint accessPoint) async {
    // origin sengaja kosong: Google Maps memakai lokasi HP sebagai titik awal.
    final opened = await widget.maps.openDirections(destination: accessPoint.mapsQuery);
    _showFailureIfNeeded(opened);
  }

  Future<void> _openSpotPin() async {
    final latitude = widget.spot.latitude;
    final longitude = widget.spot.longitude;
    if (latitude == null || longitude == null) return;
    final opened = await widget.maps.open(GeoPoint(latitude, longitude));
    _showFailureIfNeeded(opened);
  }

  void _showFailureIfNeeded(bool opened) {
    if (opened || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aplikasi peta tidak bisa dibuka di HP ini.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accessPoint = _accessPoint;
    return SectionCard(
      icon: Icons.alt_route,
      title: 'Rute perjalanan',
      child: accessPoint == null
          ? const Text('Pintu masuk untuk spot ini belum tersedia.')
          : _buildPlan(accessPoint),
    );
  }

  Widget _buildPlan(AccessPoint accessPoint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pintu masuk menuju spot', style: TextStyle(fontSize: 12)),
        Text(
          accessPoint.name,
          key: const Key('access_point_name'),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          accessPoint.steps,
          textAlign: TextAlign.justify,
          style: const TextStyle(height: 1.4),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _openRoute(accessPoint),
            icon: const Icon(Icons.directions),
            label: const Text('Buka rute di Google Maps'),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _openSpotPin,
            child: const Text('Lihat titik spot di peta'),
          ),
        ),
        const Text(
          'Rute dimulai dari lokasimu saat ini. Google Maps menghitung rute darat dan penyeberangan yang ia kenal. '
          'Kalau kamu berada di pulau yang berbeda dari pintu masuk, kamu perlu pesawat atau kapal dulu, jadi ikuti '
          'langkah di atas dan cek jadwalnya. Dari pintu masuk ke spot, pakai operator selam atau kapal setempat.',
          textAlign: TextAlign.justify,
          style: TextStyle(fontSize: 11, height: 1.35),
        ),
        const SizedBox(height: 6),
        Text(
          'Sumber langkah: ${accessPoint.sources.join(', ')}.',
          style: const TextStyle(fontSize: 11, height: 1.35),
        ),
      ],
    );
  }
}
