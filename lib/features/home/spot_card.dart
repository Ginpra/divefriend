import 'package:flutter/material.dart';

import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/widgets/level_badge.dart';
import 'package:divefriend/data/models/spot.dart';

/// Kartu spot di Beranda: area foto, nama, wilayah, lencana level.
/// Foto masih placeholder: gambar hanya dipakai dari sumber berlisensi terbuka (Tahap 3).
class SpotCard extends StatelessWidget {
  const SpotCard({super.key, required this.spot, required this.onTap});

  final Spot spot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navy, AppColors.teal],
                ),
              ),
              child: const Icon(Icons.waves, size: 48, color: Colors.white),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spot.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(spot.region),
                      ],
                    ),
                  ),
                  LevelBadge(level: spot.level),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
