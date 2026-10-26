import 'package:flutter/material.dart';

import 'package:divefriend/core/app_theme.dart';

/// Pesan kecil di dalam kartu untuk kondisi error, offline, atau data kosong.
/// Beda dengan StateMessage yang memenuhi satu layar penuh.
class InlineNotice extends StatelessWidget {
  const InlineNotice({
    super.key,
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F8),
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: AppColors.textMuted),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(height: 1.4, color: AppColors.textDark),
                ),
              ),
            ],
          ),
          if (retry != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: retry, child: const Text('Coba lagi')),
            ),
        ],
      ),
    );
  }
}
