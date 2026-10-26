import 'package:flutter/material.dart';

import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/level_style.dart';
import 'package:divefriend/data/models/spot.dart';

/// Badge level penyelam (Pemula, Menengah, Lanjutan). [onDark] = tampil di atas header gelap.
class UserLevelBadge extends StatelessWidget {
  const UserLevelBadge({super.key, required this.level, this.onDark = false, this.large = false});

  final SpotLevel level;
  final bool onDark;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final background = onDark ? AppColors.mint : level.color;
    final foreground = onDark ? AppColors.navy : Colors.white;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 18 : 12, vertical: large ? 10 : 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: large ? 24 : 16, color: foreground),
          SizedBox(width: large ? 8 : 6),
          Text(
            'Level ${level.label}',
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: large ? 16 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
