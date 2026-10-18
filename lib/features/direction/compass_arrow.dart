import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:divefriend/core/app_theme.dart';

/// Panah kompas besar. [angleDegrees] adalah arah spot relatif terhadap bagian atas HP:
/// 0 berarti spot tepat di depan HP, 90 berarti di kanan. Null berarti arah belum diketahui
/// dan panah ditampilkan abu-abu menghadap atas.
class CompassArrow extends StatelessWidget {
  const CompassArrow({super.key, required this.angleDegrees});

  final double? angleDegrees;

  @override
  Widget build(BuildContext context) {
    final angle = angleDegrees;
    return SizedBox(
      width: 210,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x140B2545),
              border: Border.all(color: AppColors.teal, width: 3),
            ),
          ),
          const Positioned(
            top: 8,
            child: Text('atas HP', style: TextStyle(fontSize: 11)),
          ),
          Transform.rotate(
            angle: (angle ?? 0) * math.pi / 180,
            child: Icon(
              Icons.navigation,
              size: 120,
              color: angle == null ? Colors.grey : AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
