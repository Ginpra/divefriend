import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/app_theme.dart';
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
      appBar: AppBar(title: const Text('Semua Fitur')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(item.icon, color: AppColors.teal, size: 30),
              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(item.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, item.page),
            ),
          );
        },
      ),
    );
  }
}
