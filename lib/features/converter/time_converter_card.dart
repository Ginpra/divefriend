import 'package:flutter/material.dart';

import 'package:divefriend/core/time_zones.dart';
import 'package:divefriend/core/widgets/section_card.dart';

/// Konverter waktu WIB, WITA, WIT, dan London. Pengguna memilih tanggal, jam, dan zona asal,
/// lalu keempat zona ditampilkan sekaligus. Tanggal ikut dipilih karena London berganti antara
/// GMT dan BST sepanjang tahun. Dihitung sendiri tanpa API (lihat time_zones.dart).
class TimeConverterCard extends StatefulWidget {
  const TimeConverterCard({super.key, this.initialTime});

  /// Waktu awal (jam dinding zona WIB, dibuat dengan DateTime.utc). Kosong = saat ini.
  /// Dipakai tes supaya hasilnya tetap.
  final DateTime? initialTime;

  @override
  State<TimeConverterCard> createState() => _TimeConverterCardState();
}

class _TimeConverterCardState extends State<TimeConverterCard> {
  late DateTime _date;
  late TimeOfDay _time;
  TimeZoneId _from = TimeZoneId.wib;

  @override
  void initState() {
    super.initState();
    final start = widget.initialTime ?? utcToWall(TimeZoneId.wib, DateTime.now().toUtc());
    _date = DateTime.utc(start.year, start.month, start.day);
    _time = TimeOfDay(hour: start.hour, minute: start.minute);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime.utc(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null) return;
    setState(() {
      _time = picked;
    });
  }

  void _selectZone(TimeZoneId zone) {
    setState(() {
      _from = zone;
    });
  }

  @override
  Widget build(BuildContext context) {
    final wall = DateTime.utc(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final fromUtc = wallToUtc(_from, wall);

    return SectionCard(
      icon: Icons.public,
      title: 'Konverter waktu',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(
                    '${_date.day.toString().padLeft(2, '0')}-'
                    '${_date.month.toString().padLeft(2, '0')}-${_date.year}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text(formatClock(wall)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Jam di atas adalah waktu', style: TextStyle(fontWeight: FontWeight.w600)),
          Wrap(
            spacing: 8,
            children: [
              for (final zone in TimeZoneId.values)
                ChoiceChip(
                  label: Text(zone.label),
                  selected: _from == zone,
                  onSelected: (_) => _selectZone(zone),
                ),
            ],
          ),
          const Divider(height: 28),
          for (final zone in TimeZoneId.values)
            _buildZoneRow(zone, wall, fromUtc),
          const SizedBox(height: 8),
          const Text(
            'WIB, WITA, dan WIT tidak memakai waktu musim panas. London memakai BST dari hari '
            'Minggu terakhir bulan Maret sampai hari Minggu terakhir bulan Oktober.',
            textAlign: TextAlign.justify,
            style: TextStyle(fontSize: 11, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneRow(TimeZoneId zone, DateTime wall, DateTime fromUtc) {
    final zoneWall = utcToWall(zone, fromUtc);
    final shift = dayShiftNote(wall, zoneWall);
    final label = zoneLabelAt(zone, fromUtc);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text('${zone.description} ($label)')),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatClock(zoneWall),
                key: Key('time_${zone.name}'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (shift != null) Text(shift, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
