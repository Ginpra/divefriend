import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DiveFriendApp());
}

/// Warna utama sesuai brief desain: biru tua + teal, aksen oranye untuk tombol utama.
class AppColors {
  static const Color navy = Color(0xFF0B2545);
  static const Color teal = Color(0xFF13A89E);
  static const Color orange = Color(0xFFF28C28);
}

class DiveFriendApp extends StatelessWidget {
  const DiveFriendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiveFriend',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          primary: AppColors.navy,
          secondary: AppColors.teal,
          tertiary: AppColors.orange,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.black,
          ),
        ),
      ),
      home: const BuildCheckPage(),
    );
  }
}

/// Layar sementara Tahap 0: hanya untuk membuktikan app terbangun dan jalan di HP asli.
/// Layar ini dibuang/diganti di Tahap 1.
class BuildCheckPage extends StatefulWidget {
  const BuildCheckPage({super.key});

  @override
  State<BuildCheckPage> createState() => _BuildCheckPageState();
}

class _BuildCheckPageState extends State<BuildCheckPage> {
  int _tapCount = 0;

  String get _buildMode {
    if (kReleaseMode) return 'release';
    if (kProfileMode) return 'profile';
    return 'debug';
  }

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Sistem operasi', Platform.operatingSystem),
      MapEntry('Versi OS', Platform.operatingSystemVersion),
      MapEntry('Mode build', _buildMode),
      MapEntry('Jumlah ketukan', '$_tapCount'),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('DiveFriend'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tahap 0: uji build di HP asli',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 140, child: Text(row.key)),
                    Expanded(child: Text(row.value)),
                  ],
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => setState(() => _tapCount++),
                child: const Text('Ketuk untuk tes hot reload'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
