import 'package:flutter/material.dart';

import 'package:divefriend/core/widgets/level_badge.dart';
import 'package:divefriend/core/widgets/spot_photo_view.dart';
import 'package:divefriend/data/models/spot.dart';

/// Kartu spot di Beranda: foto (lencana level di pojok), nama, wilayah, dan kalimat pembuka.
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
            Stack(
              children: [
                SpotPhotoView(photo: spot.photo, height: 150),
                Positioned(
                  top: 10,
                  right: 10,
                  child: LevelBadge(level: spot.level),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 16),
                      const SizedBox(width: 4),
                      Text(spot.region),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    spot.tagline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
