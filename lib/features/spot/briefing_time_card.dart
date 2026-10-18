import 'package:flutter/material.dart';

import 'package:divefriend/core/time_zones.dart';
import 'package:divefriend/core/widgets/inline_notice.dart';
import 'package:divefriend/core/widgets/section_card.dart';
import 'package:divefriend/data/models/spot.dart';

/// Jam briefing simulasi tim: pukul 07.30 waktu setempat spot.
const int briefingHour = 7;
const int briefingMinute = 30;

/// Jam briefing di spot dibandingkan dengan jam di London. Dihitung sendiri tanpa API,
/// memakai tanggal hari ini supaya aturan musim panas London (BST atau GMT) ikut benar.
/// [now] bisa diisi saat tes agar hasilnya tetap.
class BriefingTimeCard extends StatelessWidget {
  const BriefingTimeCard({super.key, required this.spot, this.now});

  final Spot spot;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final zone = zoneFromLabel(spot.timeZoneLabel);
    return SectionCard(
      icon: Icons.schedule,
      title: 'Jam briefing',
      child: zone == null
          ? const InlineNotice(
              icon: Icons.info_outline,
              message: 'Jam briefing tidak tersedia karena zona waktu spot belum diketahui.',
            )
          : _buildTimes(zone),
    );
  }

  Widget _buildTimes(TimeZoneId zone) {
    final nowUtc = (now ?? DateTime.now()).toUtc();
    final today = utcToWall(zone, nowUtc);
    final localBriefing = DateTime.utc(
      today.year,
      today.month,
      today.day,
      briefingHour,
      briefingMinute,
    );
    final briefingUtc = wallToUtc(zone, localBriefing);
    final londonBriefing = utcToWall(TimeZoneId.london, briefingUtc);
    final shift = dayShiftNote(localBriefing, londonBriefing);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TimeRow(label: 'Setempat', value: '${formatClock(localBriefing)} ${zone.label}'),
        _TimeRow(
          label: 'London',
          value:
              '${formatClock(londonBriefing)} ${zoneLabelAt(TimeZoneId.london, briefingUtc)}'
              '${shift == null ? '' : ' ($shift)'}',
        ),
        const SizedBox(height: 8),
        const Text(
          'Jam briefing simulasi pukul 07.30 waktu setempat. Selisih dengan London mengikuti '
          'aturan waktu musim panas Inggris pada tanggal hari ini.',
          textAlign: TextAlign.justify,
          style: TextStyle(fontSize: 12, height: 1.35),
        ),
      ],
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
