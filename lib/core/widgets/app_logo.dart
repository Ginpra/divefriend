import 'package:flutter/material.dart';

import 'package:divefriend/core/app_theme.dart';

/// Logo DiveFriend (masker dan snorkel) dari assets/images/logo.png, dipotong membulat seperti ikon aplikasi.
/// Kalau file gambar gagal dimuat, yang tampil ikon ombak sederhana (aplikasi tidak error).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.26),
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: AppColors.mint,
          child: Icon(Icons.waves, size: size * 0.55, color: AppColors.navy),
        ),
      ),
    );
  }
}
