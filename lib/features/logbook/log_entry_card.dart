import 'package:flutter/material.dart';

import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/data/models/log_entry.dart';
import 'package:divefriend/services/logbook_service.dart';

/// Satu halaman di logbook. [isBroken] menandai catatan yang gagal dicek (garis merah).
class LogEntryCard extends StatelessWidget {
  const LogEntryCard({super.key, required this.entry, this.isBroken = false});

  final LogEntry entry;
  final bool isBroken;

  /// Hash panjang diringkas: delapan karakter awal dan empat karakter akhir.
  static String shortHash(String hash) {
    if (hash.length <= 14) return hash;
    return '${hash.substring(0, 8)}...${hash.substring(hash.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isBroken ? Colors.red.shade700 : const Color(0x330B2545);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isBroken ? 2 : 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 8,
              decoration: BoxDecoration(
                color: isBroken ? Colors.red.shade700 : AppColors.teal,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Penyelaman #${entry.seq}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Text(formatDisplayDate(entry.diveDate)),
          ],
        ),
        const SizedBox(height: 2),
        Text(entry.spotName, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 14,
          children: [
            _Fact(icon: Icons.arrow_downward, text: '${entry.maxDepthM} m'),
            _Fact(icon: Icons.timer_outlined, text: '${entry.bottomTimeMin} menit'),
          ],
        ),
        if (entry.notes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            entry.notes,
            textAlign: TextAlign.justify,
            style: const TextStyle(height: 1.35),
          ),
        ],
        const Divider(height: 20),
        Text(
          'Hash ${shortHash(entry.hash)}',
          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
        ),
        Text(
          entry.seq == 1
              ? 'Catatan pertama, tidak terhubung ke catatan sebelumnya'
              : 'Terhubung ke #${entry.seq - 1} (${shortHash(entry.prevHash)})',
          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
        ),
        if (isBroken)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Catatan ini gagal dicek',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.teal),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}
