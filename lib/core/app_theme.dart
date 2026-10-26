import 'package:flutter/material.dart';

/// Token warna DiveFriend. Nama lama (navy, teal, orange, background, textDark) dipertahankan
/// supaya layar yang belum dirombak tetap jalan.
class AppColors {
  // Warna lama
  static const Color navy = Color(0xFF0B2545);
  static const Color teal = Color(0xFF13A89E);
  static const Color orange = Color(0xFFF28C28);
  static const Color background = Color(0xFFF2F8FB);
  static const Color textDark = Color(0xFF10212F);

  // Warna baru
  static const Color navyDeep = Color(0xFF06182E);
  static const Color ocean = Color(0xFF0E5C73);
  static const Color tealDeep = Color(0xFF0A6F6A);
  static const Color mint = Color(0xFF3DEBC8);
  static const Color mintSoft = Color(0xFFD8F7F0);
  static const Color surface = Colors.white;
  static const Color line = Color(0x1F0B2545);
  static const Color textMuted = Color(0xFF4A5E6E);
  static const Color sand = Color(0xFFFFF4E0);
  static const Color sandText = Color(0xFF5D3A00);
}

/// Radius sudut: satu nilai per jenis komponen.
class AppRadius {
  static const double card = 24;
  static const double button = 28;
  static const double field = 16;
  static const double chip = 16;
  static const double sheet = 32;
}

/// Tinggi bar navigasi sistem di bawah layar (tiga tombol atau garis gestur). Ditambahkan ke jarak
/// bawah daftar yang bisa digulir supaya isi terakhir tidak tertutup tombol HP.
double bottomInset(BuildContext context) => MediaQuery.paddingOf(context).bottom;

/// Jarak berpola kelipatan 4.
class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppFonts {
  static const String heading = 'LilitaOne';
  static const String body = 'Poppins';
}

class AppShadows {
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x1A0B2545),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];
}

/// Gradasi gelap di bawah foto supaya teks putih tetap terbaca (kontras minimal 4,5 banding 1).
class AppGradients {
  static const LinearGradient photoOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00061830), Color(0x99061830), Color(0xEB061830)],
    stops: [0.35, 0.7, 1.0],
  );

  static const LinearGradient deepSea = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.navyDeep, AppColors.ocean],
  );
}

TextTheme _buildTextTheme() {
  const heading = TextStyle(
    fontFamily: AppFonts.heading,
    fontWeight: FontWeight.w400,
    color: AppColors.navy,
    height: 1.2,
  );
  const body = TextStyle(
    fontFamily: AppFonts.body,
    color: AppColors.textDark,
  );
  return TextTheme(
    headlineLarge: heading.copyWith(fontSize: 32),
    headlineMedium: heading.copyWith(fontSize: 28),
    headlineSmall: heading.copyWith(fontSize: 24),
    titleLarge: heading.copyWith(fontSize: 22),
    titleMedium: body.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall: body.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge: body.copyWith(fontSize: 16, height: 1.5),
    bodyMedium: body.copyWith(fontSize: 14, height: 1.5),
    bodySmall: body.copyWith(
      fontSize: 12,
      height: 1.4,
      color: AppColors.textMuted,
    ),
    labelLarge: body.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: body.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall: body.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
  );
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.teal,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.navy,
    onPrimary: Colors.white,
    secondary: AppColors.tealDeep,
    onSecondary: Colors.white,
    tertiary: AppColors.mint,
    onTertiary: AppColors.navy,
    surface: AppColors.surface,
    onSurface: AppColors.textDark,
    outline: AppColors.line,
  );

  final textTheme = _buildTextTheme();
  const pill = StadiumBorder();

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: AppFonts.body,
    textTheme: textTheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.navyDeep,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge!.copyWith(color: Colors.white),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shadowColor: const Color(0x330B2545),
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.mint,
        foregroundColor: AppColors.navy,
        disabledBackgroundColor: const Color(0xFFD5DEE4),
        disabledForegroundColor: const Color(0xFF5A6B78),
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: pill,
        textStyle: textTheme.labelLarge!.copyWith(fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: pill,
        side: const BorderSide(color: AppColors.navy, width: 1.2),
        textStyle: textTheme.labelLarge!.copyWith(fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.tealDeep,
        minimumSize: const Size(48, 48),
        shape: pill,
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: textTheme.bodyMedium!.copyWith(color: AppColors.textMuted),
      labelStyle: textTheme.bodyMedium!.copyWith(color: AppColors.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: Color(0x4D0B2545)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.tealDeep, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: Color(0xFFB3261E)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: Color(0xFFB3261E), width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.mint,
      disabledColor: const Color(0xFFE6EDF1),
      side: const BorderSide(color: Color(0x4D0B2545)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      labelStyle: textTheme.labelLarge!.copyWith(color: AppColors.navy),
      secondaryLabelStyle: textTheme.labelLarge!.copyWith(color: AppColors.navy),
      checkmarkColor: AppColors.navy,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: const Color(0x330B2545),
      height: 72,
      indicatorColor: AppColors.mint,
      indicatorShape: const StadiumBorder(),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: selected ? AppColors.navy : AppColors.textMuted,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelMedium!.copyWith(
          color: selected ? AppColors.navy : AppColors.textMuted,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        );
      }),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.navyDeep,
      contentTextStyle: textTheme.bodyMedium!.copyWith(color: Colors.white),
      actionTextColor: AppColors.mint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.tealDeep,
      circularTrackColor: AppColors.mintSoft,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? AppColors.navy : const Color(0xFF6B7C89)),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? AppColors.mint : const Color(0xFFE1E8ED)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
  );
}
