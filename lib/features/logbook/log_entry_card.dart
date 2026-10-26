import 'package:flutter/material.dart';

import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/time_zones.dart';
import 'package:divefriend/data/models/log_entry.dart';
import 'package:divefriend/services/logbook_service.dart';

/// Satu halaman di logbook. [isBroken] menandai catatan yang gagal dicek (garis merah).
/// [onEdit] dan [onDelete] menampilkan tombol Ubah dan Hapus kalau diisi.
class LogEntryCard extends StatelessWidget {
  const LogEntryCard({
    super.key,
    required this.entry,
    this.isBroken = false,
    this.onEdit,
    this.onDelete,
  });

  final LogEntry entry;
  final bool isBroken;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// "Diubah 18-10-2026 14.05" dalam waktu HP, atau null kalau catatan belum pernah diubah.
  static String? updatedLabel(String? updatedAtIso) {
    if (updatedAtIso == null) return null;
    final parsed = DateTime.tryParse(updatedAtIso);
    if (parsed == null) return null;
    final local = parsed.toLocal();
    final date = '${local.day.toString().padLeft(2, '0')}-${local.month.toString().padLeft(2, '0')}-${local.year}';
    return 'Diubah $date ${formatClock(local)}';
  }

  /// Hash panjang diringkas: delapan karakter awal dan empat karakter akhir.
  static String shortHash(String hash) {
    if (hash.length <= 14) return hash;
    return '${hash.substring(0, 8)}...${hash.substring(hash.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isBroken ? Colors.red.shade700 : AppColors.line;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: borderColor, width: isBroken ? 2 : 1),
        boxShadow: AppShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 8,
              decoration: BoxDecoration(
                color: isBroken ? Colors.red.shade700 : AppColors.tealDeep,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final edited = updatedLabel(entry.updatedAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Penyelaman #${entry.seq}',
                style: const TextStyle(fontFamily: AppFonts.heading, fontSize: 18, color: AppColors.navy),
              ),
            ),
            Text(formatDisplayDate(entry.diveDate), style: const TextStyle(color: AppColors.textMuted)),
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
        if (edited != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(edited, key: const Key('updated_label'), style: const TextStyle(fontSize: 11)),
          ),
        if (onEdit != null || onDelete != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onEdit != null)
                TextButton.icon(
                  key: Key('edit_${entry.seq}'),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Ubah'),
                ),
              if (onDelete != null)
                TextButton.icon(
                  key: Key('delete_${entry.seq}'),
                  onPressed: onDelete,
                  style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Hapus'),
                ),
            ],
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
        Icon(icon, size: 16, color: AppColors.tealDeep),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}
