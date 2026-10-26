import 'package:flutter/material.dart';

import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/data/models/spot.dart';

/// Foto spot dari internet. Kalau belum ada foto, gagal dimuat, atau sedang offline,
/// yang tampil adalah placeholder laut dalam (aplikasi tidak error).
/// [withOverlay] menambah gradasi gelap di bagian bawah supaya teks putih di atas foto terbaca.
class SpotPhotoView extends StatelessWidget {
  const SpotPhotoView({
    super.key,
    required this.photo,
    required this.height,
    this.withOverlay = false,
  });

  final SpotPhoto? photo;
  final double height;
  final bool withOverlay;

  @override
  Widget build(BuildContext context) {
    final currentPhoto = photo;
    final Widget base = currentPhoto == null
        ? _placeholder()
        : Image.network(
            currentPhoto.url,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : _placeholder(),
            errorBuilder: (context, error, stackTrace) => _placeholder(),
          );
    if (!withOverlay) return base;
    return Stack(
      children: [
        base,
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: AppGradients.photoOverlay),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppGradients.deepSea),
      child: const Icon(Icons.waves, size: 40, color: Colors.white54),
    );
  }
}
