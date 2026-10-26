import 'package:flutter/material.dart';

import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/widgets/level_badge.dart';
import 'package:divefriend/core/widgets/spot_photo_view.dart';
import 'package:divefriend/data/models/spot.dart';

/// Kartu spot di Beranda: foto besar dengan gradasi gelap, nama, wilayah, kalimat pembuka,
/// dan lencana level di pojok.
class SpotCard extends StatelessWidget {
  const SpotCard({super.key, required this.spot, required this.onTap, this.note});

  final Spot spot;
  final VoidCallback onTap;

  /// Teks kecil di pojok kanan atas, dipakai untuk skor kecocokan di filter Rekomendasi.
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Stack(
          children: [
            SpotPhotoView(photo: spot.photo, height: 230, withOverlay: true),
            Positioned(
              top: AppSpace.md,
              left: AppSpace.md,
              child: LevelBadge(level: spot.level),
            ),
            if (note != null)
              Positioned(
                top: AppSpace.md,
                right: AppSpace.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    note!,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: AppSpace.lg,
              right: AppSpace.lg,
              bottom: AppSpace.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spot.name,
                    style: const TextStyle(
                      fontFamily: AppFonts.heading,
                      fontSize: 24,
                      height: 1.15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 16, color: Colors.white),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: Text(
                          spot.region,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    spot.tagline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(height: 1.4, fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
