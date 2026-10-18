import 'package:flutter/material.dart';

import 'package:divefriend/core/formatters.dart';
import 'package:divefriend/core/widgets/inline_notice.dart';
import 'package:divefriend/core/widgets/section_card.dart';
import 'package:divefriend/data/models/sea_conditions.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/services/api_failure.dart';
import 'package:divefriend/services/marine_service.dart';

/// Kartu gelombang laut hari ini di Detail Spot. Menangani lima kondisi:
/// spot tanpa koordinat, memuat, error atau offline (dengan tombol coba lagi),
/// data kosong dari model, dan data siap tampil.
class SeaConditionsCard extends StatefulWidget {
  const SeaConditionsCard({super.key, required this.spot, required this.marine});

  final Spot spot;
  final MarineService marine;

  @override
  State<SeaConditionsCard> createState() => _SeaConditionsCardState();
}

class _SeaConditionsCardState extends State<SeaConditionsCard> {
  Future<SeaConditions>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Tidak memanggil API kalau spot belum punya koordinat.
  void _load() {
    final latitude = widget.spot.latitude;
    final longitude = widget.spot.longitude;
    _future = (latitude == null || longitude == null)
        ? null
        : widget.marine.fetchToday(latitude: latitude, longitude: longitude);
  }

  void _retry() {
    setState(() {
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      icon: Icons.waves,
      title: 'Gelombang laut hari ini',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBody(),
          const SizedBox(height: 10),
          const Text(
            'Perkiraan model untuk titik pusat kawasan, bukan kondisi di titik selam. '
            'Sumber: Open-Meteo.com (Marine Weather API, termasuk model gelombang DWD).',
            textAlign: TextAlign.justify,
            style: TextStyle(fontSize: 11, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final future = _future;
    if (future == null) {
      return const InlineNotice(
        icon: Icons.location_off_outlined,
        message: 'Gelombang tidak tersedia karena spot ini belum punya koordinat.',
      );
    }
    return FutureBuilder<SeaConditions>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Memuat data gelombang'),
            ],
          );
        }
        final error = snapshot.error;
        if (error != null) {
          return InlineNotice(
            icon: Icons.cloud_off,
            message: failureText(error, 'gelombang'),
            onRetry: _retry,
          );
        }
        final conditions = snapshot.data;
        if (conditions == null || !conditions.hasData) {
          return const InlineNotice(
            icon: Icons.info_outline,
            message:
                'Model belum punya data gelombang untuk titik ini. Coba lagi nanti atau periksa kondisi laut langsung dengan operator selam.',
          );
        }
        return _buildValues(conditions);
      },
    );
  }

  Widget _buildValues(SeaConditions conditions) {
    return Column(
      children: [
        _WaveRow(label: 'Saat ini', meters: conditions.currentWaveHeightM),
        _WaveRow(label: 'Tertinggi hari ini', meters: conditions.maxWaveHeightTodayM),
      ],
    );
  }
}

class _WaveRow extends StatelessWidget {
  const _WaveRow({required this.label, required this.meters});

  final String label;
  final double? meters;

  @override
  Widget build(BuildContext context) {
    final value = meters;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value == null ? 'tidak tersedia' : '${formatNumber(value, decimals: 1)} m',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
