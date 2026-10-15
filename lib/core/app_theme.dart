import 'package:flutter/material.dart';

/// Palet warna sesuai brief desain: biru tua + teal, aksen oranye untuk tombol utama.
class AppColors {
  static const Color navy = Color(0xFF0B2545);
  static const Color teal = Color(0xFF13A89E);
  static const Color orange = Color(0xFFF28C28);
  static const Color background = Color(0xFFF4F8FA);
  static const Color textDark = Color(0xFF10212F);
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.teal,
    primary: AppColors.navy,
    secondary: AppColors.teal,
    tertiary: AppColors.orange,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.black,
        minimumSize: const Size(0, 48),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
      fillColor: Colors.white,
    ),
  );
}
