import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/geo_math.dart';
import 'package:divefriend/core/widgets/state_message.dart';
import 'package:divefriend/data/models/geo_point.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/features/direction/direction_screen.dart';
import 'package:divefriend/features/spot/spot_detail_screen.dart';

/// Peta OpenStreetMap yang tertanam di aplikasi. Semua spot tampil sebagai penanda, memilih spot
/// (lewat penanda atau daftar di bawah) memindahkan peta ke spot itu. Kalau lokasi pengguna terbaca,
/// tersedia garis lurus dari lokasi pengguna ke spot.
///
/// Garis yang tampil adalah garis lurus, bukan rute jalan: spot ada di pulau lain, jadi rute
/// jalan tidak ada. Untuk petunjuk belokan, tombol Google Maps tetap tersedia.
class SpotMapScreen extends StatefulWidget {
  const SpotMapScreen({super.key, required this.services, this.initialSpot});

  final AppServices services;
  final Spot? initialSpot;

  @override
  State<SpotMapScreen> createState() => _SpotMapScreenState();
}

class _SpotMapScreenState extends State<SpotMapScreen> {
  // Sesuai kebijakan tile OpenStreetMap, aplikasi harus menyebut identitasnya lewat userAgentPackageName.
  static const String _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String _packageName = 'com.example.divefriend';

  late final Future<List<Spot>> _spotsFuture = _loadSpots();
  Spot? _selected;
  GeoPoint? _position;
  bool _locating = true;
  bool _showLine = false;

  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  Future<List<Spot>> _loadSpots() async {
    final all = await widget.services.spots.getSpots();
    return all.where((spot) => spot.latitude != null && spot.longitude != null).toList();
  }

  /// Satu pembacaan posisi saja (bukan aliran terus-menerus), karena peta tidak perlu melacak gerakan.
  Future<void> _loadPosition() async {
    GeoPoint? point;
    try {
      point = await widget.services.location.positions().first.timeout(const Duration(seconds: 12));
    } catch (_) {
      point = null;
    }
    if (!mounted) return;
    setState(() {
      _position = point;
      _locating = false;
    });
  }

  void _select(Spot spot) {
    setState(() {
      _selected = spot;
      _showLine = false;
    });
  }

  LatLng _latLng(Spot spot) => LatLng(spot.latitude!, spot.longitude!);

  MapOptions _optionsFor(Spot spot) {
    final position = _position;
    if (_showLine && position != null) {
      return MapOptions(
        initialCameraFit: CameraFit.coordinates(
          coordinates: [LatLng(position.latitude, position.longitude), _latLng(spot)],
          padding: const EdgeInsets.all(48),
          maxZoom: 10,
        ),
      );
    }
    return MapOptions(initialCenter: _latLng(spot), initialZoom: 9);
  }

  Future<void> _openGoogleMaps(Spot spot) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await widget.services.maps.open(GeoPoint(spot.latitude!, spot.longitude!));
    if (!ok) {
      messenger.showSnackBar(const SnackBar(content: Text('Aplikasi peta tidak bisa dibuka.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peta Spot')),
      body: FutureBuilder<List<Spot>>(
        future: _spotsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final spots = snapshot.data;
          if (snapshot.hasError || spots == null || spots.isEmpty) {
            return const StateMessage(
              icon: Icons.map_outlined,
              title: 'Belum ada spot di peta',
              message: 'Spot dengan koordinat belum tersedia.',
            );
          }
          final selected = _selected ?? _initialSelection(spots);
          return Column(
            children: [
              Expanded(child: _buildMap(spots, selected)),
              _buildPanel(spots, selected),
            ],
          );
        },
      ),
    );
  }

  Spot _initialSelection(List<Spot> spots) {
    final wanted = widget.initialSpot;
    if (wanted != null) {
      for (final spot in spots) {
        if (spot.id == wanted.id) return spot;
      }
    }
    return spots.first;
  }

  Widget _buildMap(List<Spot> spots, Spot selected) {
    final position = _position;
    return Stack(
      children: [
        FlutterMap(
          // Kunci berubah saat spot atau mode garis berganti, sehingga peta dibuat ulang dan langsung
          // berpusat di spot terpilih tanpa perlu MapController.
          key: ValueKey('${selected.id}-$_showLine'),
          options: _optionsFor(selected),
          children: [
            TileLayer(urlTemplate: _tileUrl, userAgentPackageName: _packageName),
            if (_showLine && position != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [LatLng(position.latitude, position.longitude), _latLng(selected)],
                    strokeWidth: 3,
                    color: AppColors.orange,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (final spot in spots)
                  Marker(
                    point: _latLng(spot),
                    width: 44,
                    height: 44,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => _select(spot),
                      child: Icon(
                        Icons.location_on,
                        size: spot.id == selected.id ? 44 : 32,
                        color: spot.id == selected.id ? AppColors.orange : AppColors.navy,
                      ),
                    ),
                  ),
                if (position != null)
                  Marker(
                    point: LatLng(position.latitude, position.longitude),
                    width: 28,
                    height: 28,
                    child: const Icon(Icons.my_location, size: 26, color: Colors.blue),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          right: 6,
          bottom: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: Colors.white70,
            child: const Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 10)),
          ),
        ),
      ],
    );
  }

  Widget _buildPanel(List<Spot> spots, Spot selected) {
    final position = _position;
    String distanceText;
    if (position != null) {
      final meters = distanceMeters(
        position.latitude,
        position.longitude,
        selected.latitude!,
        selected.longitude!,
      );
      distanceText = 'Jarak garis lurus dari lokasimu: ${formatDistance(meters)}';
    } else if (_locating) {
      distanceText = 'Mencari lokasimu...';
    } else {
      distanceText = 'Lokasimu belum terbaca (izin atau GPS mati), peta tetap bisa dipakai.';
    }

    return Material(
      color: Colors.white,
      elevation: 6,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: spots.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final spot = spots[index];
                    return ChoiceChip(
                      label: Text(spot.name),
                      selected: spot.id == selected.id,
                      onSelected: (_) => _select(spot),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Text(
                selected.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
              ),
              Text(selected.region, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 2),
              Text(distanceText, key: const Key('map_distance'), style: const TextStyle(fontSize: 12)),
              const Text(
                'Penanda adalah titik pusat kawasan, bukan titik selam.',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  OutlinedButton(onPressed: () => _openDetail(selected), child: const Text('Detail')),
                  OutlinedButton(onPressed: () => _openDirection(selected), child: const Text('Arah')),
                  OutlinedButton(onPressed: () => _openGoogleMaps(selected), child: const Text('Google Maps')),
                  if (position != null)
                    FilledButton(
                      onPressed: () => setState(() => _showLine = !_showLine),
                      child: Text(_showLine ? 'Sembunyikan garis' : 'Garis dari lokasiku'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(Spot spot) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SpotDetailScreen(spot: spot, services: widget.services),
      ),
    );
  }

  void _openDirection(Spot spot) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DirectionScreen(spot: spot, services: widget.services),
      ),
    );
  }
}
