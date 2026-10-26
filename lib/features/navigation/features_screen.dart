import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/widgets/ocean_decor.dart';
import 'package:divefriend/features/ai/ai_chat_screen.dart';
import 'package:divefriend/features/booking/booking_list_screen.dart';
import 'package:divefriend/features/converter/converter_screen.dart';
import 'package:divefriend/features/game/game_screen.dart';
import 'package:divefriend/features/logbook/logbook_screen.dart';
import 'package:divefriend/features/map/spot_map_screen.dart';

/// Daftar semua fitur selain Beranda, Profil, dan Saran & Kesan.
class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key, required this.services});

  final AppServices services;

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String title, String subtitle, Widget page})>[
      (
        icon: Icons.map_outlined,
        title: 'Peta Spot',
        subtitle: 'Peta OpenStreetMap, pilih spot lalu lihat jarak, detail, dan arah',
        page: SpotMapScreen(services: services),
      ),
      (
        icon: Icons.currency_exchange,
        title: 'Konversi',
        subtitle: 'Kurs mata uang dan konversi waktu WIB, WITA, WIT, London',
        page: ConverterScreen(services: services),
      ),
      (
        icon: Icons.menu_book_outlined,
        title: 'Logbook',
        subtitle: 'Catatan penyelaman dengan pengecekan integritas',
        page: LogbookScreen(services: services),
      ),
      (
        icon: Icons.event_available_outlined,
        title: 'Booking',
        subtitle: 'Pesan trip simulasi dengan pengingat jam kumpul',
        page: BookingListScreen(services: services),
      ),
      (
        icon: Icons.sports_esports_outlined,
        title: 'Game',
        subtitle: 'Kuis tebak biota dan goyang untuk biota hari ini',
        page: GameScreen(services: services),
      ),
      (
        icon: Icons.smart_toy_outlined,
        title: 'Asisten AI',
        subtitle: 'Tanya informasi umum seputar spot selam',
        page: AiChatScreen(services: services),
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          const OceanHeader(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Semua Fitur',
                style: TextStyle(
                  fontFamily: AppFonts.heading,
                  fontSize: 30,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpace.lg),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpace.md),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.lg,
                      vertical: AppSpace.sm,
                    ),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.mintSoft,
                      child: Icon(item.icon, color: AppColors.tealDeep, size: 28),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontFamily: AppFonts.heading,
                        fontSize: 18,
                        color: AppColors.navy,
                      ),
                    ),
                    subtitle: Text(
                      item.subtitle,
                      style: const TextStyle(height: 1.4, color: AppColors.textMuted),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.navy),
                    onTap: () => _open(context, item.page),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
