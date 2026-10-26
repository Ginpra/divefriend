import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/widgets/disclaimer_banner.dart';
import 'package:divefriend/core/widgets/level_badge.dart';
import 'package:divefriend/core/widgets/ocean_decor.dart';
import 'package:divefriend/core/widgets/spot_photo_view.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/features/direction/direction_screen.dart';
import 'package:divefriend/features/booking/booking_screen.dart';
import 'package:divefriend/features/map/spot_map_screen.dart';
import 'package:divefriend/features/spot/price_card.dart';
import 'package:divefriend/features/spot/sea_conditions_card.dart';

/// Detail spot. Gelombang (Open-Meteo) dan harga 4 mata uang (Frankfurter) masing-masing
/// punya kartu sendiri supaya layar ini tetap pendek. Jam kumpul diatur di layar Booking.
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

  void _openDirection(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DirectionScreen(spot: spot, services: services),
      ),
    );
  }

  void _openBooking(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookingScreen(services: services, spot: spot),
      ),
    );
  }

  void _openMap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SpotMapScreen(services: services, initialSpot: spot),
      ),
    );
  }

  void _showInfo(BuildContext context) {
    final photoCredit = _photoCreditText;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Info dan sumber data',
                style: TextStyle(fontFamily: AppFonts.heading, fontSize: 22, color: AppColors.navy),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                'Dasar level: ${spot.levelBasis}',
                textAlign: TextAlign.justify,
                style: const TextStyle(height: 1.5),
              ),
              if (photoCredit != null) ...[
                const SizedBox(height: AppSpace.md),
                Text(photoCredit, style: const TextStyle(color: AppColors.textMuted)),
              ],
              const SizedBox(height: AppSpace.lg),
              const Text(
                'Sumber data',
                style: TextStyle(fontFamily: AppFonts.heading, fontSize: 18, color: AppColors.navy),
              ),
              for (final source in spot.sources)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.sm),
                  child: Text(
                    '- $source',
                    style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.textMuted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              SpotPhotoView(photo: spot.photo, height: 320),
              Positioned(
                top: topInset + AppSpace.sm,
                left: AppSpace.md,
                child: Material(
                  color: Colors.white,
                  elevation: 2,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Kembali',
                    color: AppColors.navy,
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
              Positioned(
                top: topInset + AppSpace.sm,
                right: AppSpace.md,
                child: Material(
                  color: Colors.white,
                  elevation: 2,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Info dan sumber data',
                    color: AppColors.navy,
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _showInfo(context),
                  ),
                ),
              ),
              const Positioned(left: 0, right: 0, bottom: 0, child: WaveEdge()),
            ],
          ),
          const DisclaimerBanner(),
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        spot.name,
                        style: const TextStyle(
                          fontFamily: AppFonts.heading,
                          fontSize: 30,
                          height: 1.15,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    LevelBadge(level: spot.level),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 16, color: AppColors.tealDeep),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Text(
                        spot.region,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),
                Text(
                  spot.tagline,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                for (final paragraph in spot.summary.split('\n\n'))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.md),
                    child: Text(
                      paragraph,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(height: 1.55),
                    ),
                  ),
                const SizedBox(height: AppSpace.xs),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpace.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.line),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Column(
                    children: [
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
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                SeaConditionsCard(spot: spot, marine: services.marine),
                PriceCard(spot: spot, rates: services.rates),
                const SizedBox(height: AppSpace.xs),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _openBooking(context),
                    child: const Text('Booking'),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _openDirection(context),
                    child: const Text('Arah ke Spot'),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _openMap(context),
                    child: const Text('Lihat di peta'),
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
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 124,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
