import 'package:flutter/material.dart';

import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/data/models/spot.dart';

/// Foto spot dari internet. Kalau belum ada foto, gagal dimuat, atau sedang offline,
/// yang tampil adalah placeholder polos (aplikasi tidak error).
class SpotPhotoView extends StatelessWidget {
  const SpotPhotoView({super.key, required this.photo, required this.height});

  final SpotPhoto? photo;
  final double height;

  @override
  Widget build(BuildContext context) {
    final currentPhoto = photo;
    if (currentPhoto == null) return _placeholder();

    return Image.network(
      currentPhoto.url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholder(),
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      height: height,
      width: double.infinity,
      color: AppColors.navy,
      child: const Icon(Icons.waves, size: 40, color: Colors.white54),
    );
  }
}
