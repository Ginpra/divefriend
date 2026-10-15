import 'package:flutter/material.dart';

import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/widgets/disclaimer_banner.dart';
import 'package:divefriend/core/widgets/level_badge.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/features/shared/placeholder_screen.dart';

/// Detail spot. Baris yang butuh API/sensor (gelombang, harga 4 mata uang, jam briefing)
/// masih berupa penanda tahap; diisi di Tahap 4 dan seterusnya.
class SpotDetailScreen extends StatelessWidget {
  const SpotDetailScreen({super.key, required this.spot});

  final Spot spot;

  static const String _unavailable = 'tidak tersedia';

  String get _depthText {
    final depth = spot.depthMeters;
    return depth == null ? _unavailable : '${depth.toStringAsFixed(0)} m';
  }

  String get _priceText {
    final price = spot.priceEstimateIdr;
    return price == null ? _unavailable : 'Rp $price';
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
    return Scaffold(
      appBar: AppBar(title: Text(spot.name)),
      body: ListView(
        children: [
          const DisclaimerBanner(),
          Container(
            height: 160,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.navy, AppColors.teal],
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.waves, size: 56, color: Colors.white),
                SizedBox(height: 4),
                Text('Foto belum tersedia',
                    style: TextStyle(color: Colors.white)),
              ],
            ),
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
                Text(spot.region),
                if (spot.isDummy) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Data dummy untuk uji tampilan. Data tersumber diisi di Tahap 3.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 16),
                _InfoRow(label: 'Jenis', value: _typesText),
                _InfoRow(label: 'Kedalaman', value: _depthText),
                _InfoRow(
                  label: 'Musim terbaik',
                  value: spot.bestSeason ?? _unavailable,
                ),
                _InfoRow(label: 'Biota', value: _biotaText),
                _InfoRow(label: 'Harga estimasi', value: _priceText),
                _InfoRow(
                  label: 'Zona waktu',
                  value: spot.timeZoneLabel ?? _unavailable,
                ),
                _InfoRow(label: 'Sumber data', value: spot.source ?? _unavailable),
                const Divider(height: 32),
                const _InfoRow(
                  label: 'Gelombang hari ini',
                  value: 'Diisi di Tahap 4 (Open-Meteo)',
                ),
                const _InfoRow(
                  label: 'Harga 4 mata uang',
                  value: 'Diisi di Tahap 4',
                ),
                const _InfoRow(
                  label: 'Jam briefing',
                  value: 'Lokal vs London, diisi di Tahap 4',
                ),
                const SizedBox(height: 16),
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
