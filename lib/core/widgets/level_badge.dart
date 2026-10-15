import 'package:flutter/material.dart';

import 'package:divefriend/core/level_style.dart';
import 'package:divefriend/data/models/spot.dart';

/// Lencana level: teks + warna (level tidak hanya dibedakan lewat warna).
class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level});

  final SpotLevel level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: level.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        level.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
