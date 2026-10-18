import 'package:flutter/material.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(height: 1.35))),
          ],
        ),
        if (retry != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: retry, child: const Text('Coba lagi')),
          ),
      ],
    );
  }
}
