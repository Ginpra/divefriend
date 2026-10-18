import 'package:flutter/material.dart';

import 'package:divefriend/core/time_zones.dart';
import 'package:divefriend/core/widgets/inline_notice.dart';
import 'package:divefriend/core/widgets/section_card.dart';
import 'package:divefriend/data/models/spot.dart';

/// Jam kumpul awal (pukul 07.30 waktu setempat), bisa diubah pengguna lewat tombol Ubah jam.
const TimeOfDay defaultGatheringTime = TimeOfDay(hour: 7, minute: 30);

/// Jam kumpul trip di spot dibandingkan dengan jam di London. Jam kumpul adalah jam peserta berkumpul di
/// titik keberangkatan sebelum trip dimulai. Pengguna memilih jamnya sendiri, hasilnya dihitung tanpa API
/// memakai tanggal hari ini supaya aturan musim panas London (BST atau GMT) ikut benar.
/// [now] bisa diisi saat tes agar hasilnya tetap.
class GatheringTimeCard extends StatefulWidget {
  const GatheringTimeCard({super.key, required this.spot, this.now});

  final Spot spot;
  final DateTime? now;

  @override
  State<GatheringTimeCard> createState() => _GatheringTimeCardState();
}

class _GatheringTimeCardState extends State<GatheringTimeCard> {
  TimeOfDay _time = defaultGatheringTime;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null) return;
    setState(() {
      _time = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final zone = zoneFromLabel(widget.spot.timeZoneLabel);
    return SectionCard(
      icon: Icons.groups_outlined,
      title: 'Jam kumpul',
      child: zone == null
          ? const InlineNotice(
              icon: Icons.info_outline,
              message: 'Jam kumpul tidak tersedia karena zona waktu spot belum diketahui.',
            )
          : _buildTimes(zone),
    );
  }

  Widget _buildTimes(TimeZoneId zone) {
    final nowUtc = (widget.now ?? DateTime.now()).toUtc();
    final today = utcToWall(zone, nowUtc);
    final localGathering = DateTime.utc(today.year, today.month, today.day, _time.hour, _time.minute);
    final gatheringUtc = wallToUtc(zone, localGathering);
    final londonGathering = utcToWall(TimeZoneId.london, gatheringUtc);
    final shift = dayShiftNote(localGathering, londonGathering);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TimeRow(label: 'Setempat', value: '${formatClock(localGathering)} ${zone.label}'),
        _TimeRow(
          label: 'London',
          value:
              '${formatClock(londonGathering)} ${zoneLabelAt(TimeZoneId.london, gatheringUtc)}'
              '${shift == null ? '' : ' ($shift)'}',
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Ubah jam'),
          ),
        ),
        const Text(
          'Jam kumpul adalah jam peserta berkumpul di titik keberangkatan sebelum trip dimulai. Jam di atas '
          'jam simulasi, silakan ubah sesuai rencana tripmu. Selisih dengan London mengikuti aturan waktu '
          'musim panas Inggris pada tanggal hari ini.',
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
