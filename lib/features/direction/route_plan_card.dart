import 'package:flutter/material.dart';

import 'package:divefriend/core/widgets/section_card.dart';
import 'package:divefriend/data/models/access_point.dart';
import 'package:divefriend/data/models/geo_point.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/data/seed/access_points.dart';
import 'package:divefriend/services/map_launcher.dart';

/// Pilihan titik awal rute. [query] kosong berarti "lokasi saya" (Google Maps memakai posisi HP).
/// Hanya nama kota yang dikirim ke Google Maps, tanpa koordinat karangan.
class RouteStart {
  const RouteStart(this.label, this.query);

  final String label;
  final String? query;
}

const List<RouteStart> routeStarts = [
  RouteStart('Lokasi saya', null),
  RouteStart('Jakarta', 'Jakarta'),
  RouteStart('Yogyakarta', 'Yogyakarta'),
  RouteStart('Surabaya', 'Surabaya'),
  RouteStart('Denpasar', 'Denpasar'),
  RouteStart('Makassar', 'Makassar'),
  RouteStart('Medan', 'Medan'),
  RouteStart('Manado', 'Manado'),
];

/// Rencana perjalanan ke spot: pintu masuk terdekat, langkah sisa perjalanan, pilihan titik awal,
/// dan tombol membuka rute di Google Maps. Rute Google Maps dihitung sampai pintu masuk, karena
/// titik pusat spot biasanya ada di laut dan tidak bisa dirutekan lewat jalan atau penyeberangan.
class RoutePlanCard extends StatefulWidget {
  const RoutePlanCard({super.key, required this.spot, required this.maps});

  final Spot spot;
  final MapLauncher maps;

  @override
  State<RoutePlanCard> createState() => _RoutePlanCardState();
}

class _RoutePlanCardState extends State<RoutePlanCard> {
  int _startIndex = 0;

  AccessPoint? get _accessPoint => accessPointsBySpotId[widget.spot.id];

  void _selectStart(int index) {
    setState(() {
      _startIndex = index;
    });
  }

  Future<void> _openRoute(AccessPoint accessPoint) async {
    final opened = await widget.maps.openDirections(
      origin: routeStarts[_startIndex].query,
      destination: accessPoint.mapsQuery,
    );
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
        const Divider(height: 24),
        const Text('Mulai dari', style: TextStyle(fontWeight: FontWeight.w600)),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < routeStarts.length; i++)
              ChoiceChip(
                label: Text(routeStarts[i].label),
                selected: _startIndex == i,
                onSelected: (_) => _selectStart(i),
              ),
          ],
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
          'Google Maps menghitung rute darat dan penyeberangan yang ia kenal. Kalau titik awal dan pintu masuk '
          'berbeda pulau, kamu perlu pesawat atau kapal dulu, jadi ikuti langkah di atas dan cek jadwalnya. '
          'Dari pintu masuk ke spot, pakai operator selam atau kapal setempat.',
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
