import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/widgets/disclaimer_banner.dart';
import 'package:divefriend/core/widgets/level_badge.dart';
import 'package:divefriend/core/widgets/spot_photo_view.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/features/shared/placeholder_screen.dart';
import 'package:divefriend/features/spot/briefing_time_card.dart';
import 'package:divefriend/features/spot/price_card.dart';
import 'package:divefriend/features/spot/sea_conditions_card.dart';

/// Detail spot. Gelombang (Open-Meteo), harga 4 mata uang (Frankfurter), dan jam briefing
/// (hitung sendiri) masing-masing punya kartu sendiri supaya layar ini tetap pendek.
class SpotDetailScreen extends StatelessWidget {
  const SpotDetailScreen({super.key, required this.spot, required this.services});

  final Spot spot;
  final AppServices services;

  static const String _unavailable = 'tidak tersedia';

  String get _coordinateText {
    final latitude = spot.latitude;
    final longitude = spot.longitude;
    if (latitude == null || longitude == null) return _unavailable;
    return '${latitude.toStringAsFixed(3)}, ${longitude.toStringAsFixed(3)} (titik pusat kawasan)';
  }

  /// Teks kredit foto, hanya ada kalau data kreditnya diisi (foto berlisensi atribusi).
  String? get _photoCreditText {
    final photo = spot.photo;
    final credit = photo?.credit;
    if (photo == null || credit == null) return null;
    final license = photo.license;
    return license == null ? 'Foto: $credit' : 'Foto: $credit ($license)';
  }

  String get _biotaText =>
      spot.biota.isEmpty ? _unavailable : spot.biota.join(', ');

  String get _typesText => spot.types.map((type) => type.label).join(', ');

  void _openPlaceholder(BuildContext context, String title, int stage) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaceholderScreen(title: title, stage: stage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = spot.photo;
    final photoCredit = _photoCreditText;

    return Scaffold(
      appBar: AppBar(title: Text(spot.name)),
      body: ListView(
        children: [
          const DisclaimerBanner(),
          SpotPhotoView(photo: photo, height: 200),
          if (photoCredit != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text(photoCredit, style: const TextStyle(fontSize: 11)),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        spot.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    LevelBadge(level: spot.level),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 16),
                    const SizedBox(width: 4),
                    Expanded(child: Text(spot.region)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  spot.tagline,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 12),
                for (final paragraph in spot.summary.split('\n\n'))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      paragraph,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                const SizedBox(height: 4),
                _InfoRow(label: 'Jenis', value: _typesText),
                _InfoRow(label: 'Koordinat', value: _coordinateText),
                _InfoRow(label: 'Kedalaman', value: spot.depthText ?? _unavailable),
                _InfoRow(
                  label: 'Musim terbaik',
                  value: spot.bestSeason ?? _unavailable,
                ),
                _InfoRow(label: 'Biota', value: _biotaText),
                _InfoRow(
                  label: 'Zona waktu',
                  value: spot.timeZoneLabel ?? _unavailable,
                ),
                const SizedBox(height: 8),
                Text(
                  'Dasar level: ${spot.levelBasis}',
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
                const Divider(height: 32),
                SeaConditionsCard(spot: spot, marine: services.marine),
                PriceCard(spot: spot, rates: services.rates),
                BriefingTimeCard(spot: spot),
                const SizedBox(height: 2),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () =>
                        _openPlaceholder(context, 'Arah ke Spot', 5),
                    child: const Text('Arah ke Spot'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _openPlaceholder(context, 'Booking', 8),
                    child: const Text('Booking'),
                  ),
                ),
                const Divider(height: 32),
                const Text(
                  'Sumber data',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                for (final source in spot.sources)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('- $source', style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
