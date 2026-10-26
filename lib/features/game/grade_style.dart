import 'package:flutter/material.dart';

import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/encounter_grade.dart';

/// Tampilan tiap grade: warna, ikon, dan jumlah percikan. Dipisah dari encounter_grade.dart
/// supaya logika undian tetap Dart murni dan mudah dites.
extension GradeStyle on EncounterGrade {
  /// Warna utama: garis tepi dan percikan.
  Color get color => switch (this) {
        EncounterGrade.biasa => const Color(0xFF5F7A8C),
        EncounterGrade.langka => const Color(0xFF1E88E5),
        EncounterGrade.epik => const Color(0xFF8E44AD),
        EncounterGrade.legendaris => const Color(0xFFF5B301),
      };

  /// Latar lembut untuk chip dan panggung.
  Color get softColor => switch (this) {
        EncounterGrade.biasa => const Color(0xFFEAF0F4),
        EncounterGrade.langka => const Color(0xFFE3F0FD),
        EncounterGrade.epik => const Color(0xFFF1E5F7),
        EncounterGrade.legendaris => const Color(0xFFFFF3CC),
      };

  /// Warna teks yang tetap terbaca di atas [softColor].
  Color get textColor => switch (this) {
        EncounterGrade.biasa => AppColors.navy,
        EncounterGrade.langka => const Color(0xFF0D47A1),
        EncounterGrade.epik => const Color(0xFF5B2C7A),
        EncounterGrade.legendaris => const Color(0xFF6B4700),
      };

  IconData get icon => switch (this) {
        EncounterGrade.biasa => Icons.circle_outlined,
        EncounterGrade.langka => Icons.diamond_outlined,
        EncounterGrade.epik => Icons.auto_awesome,
        EncounterGrade.legendaris => Icons.star_rounded,
      };

  /// Latar panggung hasil undian. Legendaris berlatar emas.
  LinearGradient get stageGradient => switch (this) {
        EncounterGrade.legendaris => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF3CC), Color(0xFFFFD54F)],
          ),
        _ => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [softColor, Colors.white],
          ),
      };

  /// Jumlah percikan yang menyebar saat grade ini keluar. Biasa tanpa percikan.
  int get sparkleCount => switch (this) {
        EncounterGrade.biasa => 0,
        EncounterGrade.langka => 8,
        EncounterGrade.epik => 14,
        EncounterGrade.legendaris => 28,
      };
}
